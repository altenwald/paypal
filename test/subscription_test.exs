defmodule Paypal.SubscriptionTest do
  use Paypal.Case

  alias Paypal.Subscription
  alias Paypal.Subscription.BillingInfo
  alias Paypal.Subscription.Capture
  alias Paypal.Subscription.Create
  alias Paypal.Subscription.Plan
  alias Paypal.Subscription.Plan.BillingCycle
  alias Paypal.Subscription.Plan.PaymentPreferences
  alias Paypal.Subscription.Plan.Taxes
  alias Paypal.Subscription.Product
  alias Paypal.Subscription.ReviseResponse
  alias Paypal.Subscription.Subscriber
  alias Paypal.Subscription.Transaction
  alias Paypal.Subscription.Transactions

  describe "Product" do
    test "types" do
      assert :physical in Keyword.keys(Product.types())
      assert :digital in Keyword.keys(Product.types())
      assert :service in Keyword.keys(Product.types())
    end

    test "create product success", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/catalogs/products", fn conn ->
        response(conn, 201, %{
          "id" => "PROD-123",
          "name" => "Video Streaming",
          "description" => "Streaming service",
          "type" => "SERVICE",
          "category" => "SOFTWARE",
          "create_time" => "2026-08-01T00:00:00Z",
          "links" => [
            %{
              "href" => "https://api.sandbox.paypal.com/v1/catalogs/products/PROD-123",
              "rel" => "self",
              "method" => "GET"
            }
          ]
        })
      end)

      assert {:ok, product} =
               Product.create(%{
                 name: "Video Streaming",
                 type: :service,
                 description: "Streaming service",
                 category: "SOFTWARE"
               })

      assert product.id == "PROD-123"
      assert product.name == "Video Streaming"
      assert product.type == :service
      assert length(product.links) == 1
    end

    test "create product error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/catalogs/products", fn conn ->
        response(conn, 400, %{
          "name" => "INVALID_REQUEST",
          "message" => "Name is required",
          "debug_id" => "dbg-prod-1"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Product.create(%{name: "Invalid", type: :service})
    end

    test "create product changeset invalid" do
      assert {:error, %{name: _}} = Product.Create.changeset(%{type: :service})
      assert {:error, %{type: _}} = Product.Create.changeset(%{name: "Test"})
    end

    test "list products", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/catalogs/products", fn conn ->
        response(conn, 200, %{
          "products" => [
            %{
              "id" => "PROD-123",
              "name" => "Video Streaming",
              "type" => "SERVICE"
            }
          ],
          "total_items" => 1,
          "total_pages" => 1,
          "links" => []
        })
      end)

      assert {:ok, list} = Product.list(page_size: 10, page: 1, total_required: true)
      assert list.total_items == 1
      assert length(list.products) == 1
    end

    test "list products error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/catalogs/products", fn conn ->
        response(conn, 500, %{
          "name" => "INTERNAL_SERVER_ERROR",
          "message" => "Server error",
          "debug_id" => "dbg-500"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INTERNAL_SERVER_ERROR"}} = Product.list()
    end

    test "show product", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/catalogs/products/PROD-123", fn conn ->
        response(conn, 200, %{
          "id" => "PROD-123",
          "name" => "Video Streaming",
          "type" => "SERVICE"
        })
      end)

      assert {:ok, product} = Product.show("PROD-123")
      assert product.id == "PROD-123"
    end

    test "show product error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/catalogs/products/PROD-999", fn conn ->
        response(conn, 404, %{
          "name" => "RESOURCE_NOT_FOUND",
          "message" => "Not found",
          "debug_id" => "dbg-404"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "RESOURCE_NOT_FOUND"}} = Product.show("PROD-999")
    end

    test "update product", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v1/catalogs/products/PROD-123", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok ==
               Product.update("PROD-123", [
                 %{op: "replace", path: "/description", value: "New description"}
               ])
    end

    test "update product error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v1/catalogs/products/PROD-123", fn conn ->
        response(conn, 400, %{
          "name" => "INVALID_PATCH_OPERATION",
          "message" => "Invalid patch",
          "debug_id" => "dbg-patch"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_PATCH_OPERATION"}} =
               Product.update("PROD-123", [%{op: "invalid"}])
    end

    test "Product network error cases" do
      Application.put_env(:paypal, :url, "http://localhost:1")
      assert {:error, _} = Product.create(%{name: "P", type: :service})
      assert {:error, _} = Product.list()
      assert {:error, _} = Product.show("PROD-1")
      assert {:error, _} = Product.update("PROD-1", [])
    end
  end

  describe "Plan" do
    test "statuses" do
      assert :created in Keyword.keys(Plan.statuses())
      assert :active in Keyword.keys(Plan.statuses())
      assert :inactive in Keyword.keys(Plan.statuses())
    end

    test "create plan success", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/plans", fn conn ->
        response(conn, 201, %{
          "id" => "P-123",
          "product_id" => "PROD-123",
          "name" => "Monthly Pro",
          "status" => "ACTIVE",
          "description" => "Monthly subscription",
          "billing_cycles" => [
            %{
              "tenure_type" => "REGULAR",
              "sequence" => 1,
              "total_cycles" => 0,
              "frequency" => %{"interval_unit" => "MONTH", "interval_count" => 1},
              "pricing_scheme" => %{
                "fixed_price" => %{"currency_code" => "EUR", "value" => "15.00"}
              }
            }
          ],
          "payment_preferences" => %{
            "auto_bill_outstanding" => true,
            "setup_fee_failure_action" => "CANCEL",
            "payment_failure_threshold" => 3
          },
          "create_time" => "2026-08-01T00:00:00Z",
          "links" => []
        })
      end)

      assert {:ok, plan} =
               Plan.create(%{
                 product_id: "PROD-123",
                 name: "Monthly Pro",
                 description: "Monthly subscription",
                 status: :active,
                 billing_cycles: [
                   %{
                     tenure_type: :regular,
                     sequence: 1,
                     total_cycles: 0,
                     frequency: %{"interval_unit" => "MONTH", "interval_count" => 1},
                     pricing_scheme: %{
                       "fixed_price" => %{"currency_code" => "EUR", "value" => "15.00"}
                     }
                   }
                 ],
                 payment_preferences: %{
                   auto_bill_outstanding: true,
                   setup_fee_failure_action: :cancel,
                   payment_failure_threshold: 3
                 }
               })

      assert plan.id == "P-123"
      assert plan.product_id == "PROD-123"
      assert plan.status == :active
      assert length(plan.billing_cycles) == 1
    end

    test "create plan error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/plans", fn conn ->
        response(conn, 400, %{
          "name" => "INVALID_REQUEST",
          "message" => "Validation error",
          "debug_id" => "dbg-plan-1"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Plan.create(%{
                 product_id: "PROD-123",
                 name: "Plan",
                 billing_cycles: [
                   %{
                     tenure_type: :regular,
                     sequence: 1,
                     frequency: %{"interval_unit" => "MONTH", "interval_count" => 1}
                   }
                 ]
               })
    end

    test "create plan changeset validations" do
      assert {:error, %{product_id: _, name: _}} = Plan.Create.changeset(%{})
      assert {:error, %{billing_cycles: _}} = Plan.Create.changeset(%{product_id: "P", name: "N"})
    end

    test "list plans", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/billing/plans", fn conn ->
        response(conn, 200, %{
          "plans" => [
            %{
              "id" => "P-123",
              "product_id" => "PROD-123",
              "name" => "Monthly Pro",
              "status" => "ACTIVE"
            }
          ],
          "total_items" => 1,
          "total_pages" => 1,
          "links" => []
        })
      end)

      assert {:ok, list} = Plan.list(product_id: "PROD-123")
      assert list.total_items == 1
      assert length(list.plans) == 1
    end

    test "list plans error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/billing/plans", fn conn ->
        response(conn, 500, %{
          "name" => "INTERNAL_SERVER_ERROR",
          "message" => "Error",
          "debug_id" => "dbg-500"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INTERNAL_SERVER_ERROR"}} = Plan.list()
    end

    test "show plan", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/billing/plans/P-123", fn conn ->
        response(conn, 200, %{
          "id" => "P-123",
          "product_id" => "PROD-123",
          "name" => "Monthly Pro",
          "status" => "ACTIVE"
        })
      end)

      assert {:ok, plan} = Plan.show("P-123")
      assert plan.id == "P-123"
    end

    test "show plan error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/billing/plans/P-999", fn conn ->
        response(conn, 404, %{
          "name" => "RESOURCE_NOT_FOUND",
          "message" => "Plan not found",
          "debug_id" => "dbg-404"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "RESOURCE_NOT_FOUND"}} = Plan.show("P-999")
    end

    test "update plan", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v1/billing/plans/P-123", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok ==
               Plan.update("P-123", [
                 %{op: "replace", path: "/description", value: "Updated description"}
               ])
    end

    test "update plan error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v1/billing/plans/P-123", fn conn ->
        response(conn, 400, %{
          "name" => "INVALID_REQUEST",
          "message" => "Cannot patch",
          "debug_id" => "dbg-patch"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Plan.update("P-123", [%{op: "replace"}])
    end

    test "activate and deactivate plan", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/plans/P-123/activate", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok == Plan.activate("P-123")

      Bypass.expect_once(bypass, "POST", "/v1/billing/plans/P-123/deactivate", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok == Plan.deactivate("P-123")
    end

    test "activate and deactivate plan errors", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/plans/P-123/activate", fn conn ->
        response(conn, 422, %{
          "name" => "UNPROCESSABLE_ENTITY",
          "message" => "Cannot activate",
          "debug_id" => "dbg-act"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} = Plan.activate("P-123")

      Bypass.expect_once(bypass, "POST", "/v1/billing/plans/P-123/deactivate", fn conn ->
        response(conn, 422, %{
          "name" => "UNPROCESSABLE_ENTITY",
          "message" => "Cannot deactivate",
          "debug_id" => "dbg-deact"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Plan.deactivate("P-123")
    end

    test "update_pricing_schemes", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/v1/billing/plans/P-123/update-pricing-schemes",
        fn conn ->
          Plug.Conn.resp(conn, 204, "")
        end
      )

      assert :ok ==
               Plan.update_pricing_schemes("P-123", [
                 %{
                   "billing_cycle_sequence" => 1,
                   "pricing_scheme" => %{
                     "fixed_price" => %{"currency_code" => "USD", "value" => "20.00"}
                   }
                 }
               ])
    end

    test "update_pricing_schemes error", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/v1/billing/plans/P-123/update-pricing-schemes",
        fn conn ->
          response(conn, 422, %{
            "name" => "UNPROCESSABLE_ENTITY",
            "message" => "Cannot update pricing",
            "debug_id" => "dbg-price"
          })
        end
      )

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Plan.update_pricing_schemes("P-123", %{"pricing_schemes" => []})
    end

    test "BillingCycle, PaymentPreferences, Taxes subschemas" do
      assert BillingCycle.changeset(%{
               "tenure_type" => "REGULAR",
               "sequence" => 1,
               "frequency" => %{"interval_unit" => "MONTH", "interval_count" => 1}
             }).valid?

      refute BillingCycle.changeset(%{}).valid?

      assert PaymentPreferences.changeset(%{
               "auto_bill_outstanding" => true,
               "setup_fee" => %{"currency_code" => "USD", "value" => "5.00"}
             }).valid?

      assert Taxes.changeset(%{"percentage" => "21.00", "inclusive" => true}).valid?
      refute Taxes.changeset(%{}).valid?
    end

    test "Plan network error cases" do
      Application.put_env(:paypal, :url, "http://localhost:1")

      assert {:error, _} =
               Plan.create(%{
                 product_id: "P-1",
                 name: "Plan",
                 billing_cycles: [
                   %{
                     tenure_type: :regular,
                     sequence: 1,
                     frequency: %{"interval_unit" => "MONTH", "interval_count" => 1}
                   }
                 ]
               })

      assert {:error, _} = Plan.list()
      assert {:error, _} = Plan.show("P-1")
      assert {:error, _} = Plan.update("P-1", [])
      assert {:error, _} = Plan.activate("P-1")
      assert {:error, _} = Plan.deactivate("P-1")
      assert {:error, _} = Plan.update_pricing_schemes("P-1", [])
    end
  end

  describe "Subscription" do
    test "statuses" do
      assert :approval_pending in Keyword.keys(Subscription.statuses())
      assert :active in Keyword.keys(Subscription.statuses())
      assert :suspended in Keyword.keys(Subscription.statuses())
      assert :cancelled in Keyword.keys(Subscription.statuses())
      assert :expired in Keyword.keys(Subscription.statuses())
    end

    test "create subscription success", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions", fn conn ->
        response(conn, 201, %{
          "id" => "I-BW452GLLEP1G",
          "plan_id" => "P-123",
          "status" => "APPROVAL_PENDING",
          "create_time" => "2026-08-01T00:00:00Z",
          "subscriber" => %{
            "name" => %{"given_name" => "Jane", "surname" => "Doe"},
            "email_address" => "jane.doe@example.com"
          },
          "links" => [
            %{
              "href" => "https://www.sandbox.paypal.com/checkoutnow?token=I-BW452GLLEP1G",
              "rel" => "approve",
              "method" => "GET"
            }
          ]
        })
      end)

      assert {:ok, sub} =
               Subscription.create(%{
                 plan_id: "P-123",
                 subscriber: %{
                   name: %{given_name: "Jane", surname: "Doe"},
                   email_address: "jane.doe@example.com"
                 },
                 application_context: %{
                   brand_name: "My SaaS",
                   locale: "en-US",
                   return_url: "https://example.com/return",
                   cancel_url: "https://example.com/cancel"
                 }
               })

      assert sub.id == "I-BW452GLLEP1G"
      assert sub.status == :approval_pending
      assert sub.subscriber.email_address == "jane.doe@example.com"
      assert length(sub.links) == 1
    end

    test "create subscription error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions", fn conn ->
        response(conn, 400, %{
          "name" => "INVALID_REQUEST",
          "message" => "Plan ID invalid",
          "debug_id" => "dbg-sub-1"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Subscription.create(%{plan_id: "P-INVALID"})
    end

    test "create subscription changeset validation" do
      assert {:error, %{plan_id: _}} = Create.changeset(%{})
    end

    test "show subscription", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/billing/subscriptions/I-123", fn conn ->
        response(conn, 200, %{
          "id" => "I-123",
          "plan_id" => "P-123",
          "status" => "ACTIVE",
          "billing_info" => %{
            "outstanding_balance" => %{"currency_code" => "USD", "value" => "0.00"},
            "failed_payments_count" => 0,
            "next_billing_time" => "2026-09-01T00:00:00Z"
          }
        })
      end)

      assert {:ok, sub} = Subscription.show("I-123", fields: "plan")
      assert sub.id == "I-123"
      assert sub.status == :active
      assert sub.billing_info.failed_payments_count == 0
    end

    test "show subscription error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/v1/billing/subscriptions/I-999", fn conn ->
        response(conn, 404, %{
          "name" => "RESOURCE_NOT_FOUND",
          "message" => "Subscription not found",
          "debug_id" => "dbg-404"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "RESOURCE_NOT_FOUND"}} =
               Subscription.show("I-999")
    end

    test "update subscription", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v1/billing/subscriptions/I-123", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok ==
               Subscription.update("I-123", [
                 %{op: "replace", path: "/custom_id", value: "NEW-CUSTOM-ID"}
               ])
    end

    test "update subscription error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "PATCH", "/v1/billing/subscriptions/I-123", fn conn ->
        response(conn, 400, %{
          "name" => "INVALID_REQUEST",
          "message" => "Patch failed",
          "debug_id" => "dbg-patch"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Subscription.update("I-123", [%{op: "replace"}])
    end

    test "revise subscription", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/revise", fn conn ->
        response(conn, 200, %{
          "plan_id" => "P-NEW-PLAN",
          "quantity" => "2",
          "plan_overridden" => false,
          "links" => [
            %{
              "href" => "https://api.sandbox.paypal.com/v1/billing/subscriptions/I-123",
              "rel" => "self",
              "method" => "GET"
            }
          ]
        })
      end)

      assert {:ok, %ReviseResponse{plan_id: "P-NEW-PLAN", quantity: "2"}} =
               Subscription.revise("I-123", %{"plan_id" => "P-NEW-PLAN", "quantity" => "2"})
    end

    test "revise subscription error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/revise", fn conn ->
        response(conn, 422, %{
          "name" => "UNPROCESSABLE_ENTITY",
          "message" => "Cannot revise",
          "debug_id" => "dbg-rev"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Subscription.revise("I-123", %{})
    end

    test "suspend, cancel, and activate subscription", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/suspend", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok == Subscription.suspend("I-123", "Pause")

      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/activate", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok == Subscription.activate("I-123", "Resume")

      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/cancel", fn conn ->
        Plug.Conn.resp(conn, 204, "")
      end)

      assert :ok == Subscription.cancel("I-123", "Quit")
    end

    test "suspend, cancel, and activate subscription errors", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/suspend", fn conn ->
        response(conn, 422, %{
          "name" => "UNPROCESSABLE_ENTITY",
          "message" => "Cannot suspend",
          "debug_id" => "dbg-sus"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Subscription.suspend("I-123")

      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/activate", fn conn ->
        response(conn, 422, %{
          "name" => "UNPROCESSABLE_ENTITY",
          "message" => "Cannot activate",
          "debug_id" => "dbg-act"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Subscription.activate("I-123")

      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/cancel", fn conn ->
        response(conn, 422, %{
          "name" => "UNPROCESSABLE_ENTITY",
          "message" => "Cannot cancel",
          "debug_id" => "dbg-can"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Subscription.cancel("I-123")
    end

    test "capture subscription", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/capture", fn conn ->
        response(conn, 200, %{
          "id" => "CAP-123",
          "status" => "COMPLETED",
          "amount_with_breakdown" => %{"currency_code" => "USD", "value" => "10.00"},
          "create_time" => "2026-08-01T00:00:00Z"
        })
      end)

      assert {:ok, %Capture{id: "CAP-123", status: :completed}} =
               Subscription.capture("I-123", %{
                 note: "Outstanding balance",
                 capture_type: "OUTSTANDING_BALANCE",
                 amount: %{currency_code: "USD", value: "10.00"}
               })
    end

    test "capture subscription error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/v1/billing/subscriptions/I-123/capture", fn conn ->
        response(conn, 422, %{
          "name" => "UNPROCESSABLE_ENTITY",
          "message" => "Cannot capture",
          "debug_id" => "dbg-cap"
        })
      end)

      assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
               Subscription.capture("I-123", %{})
    end

    test "transactions list", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/v1/billing/subscriptions/I-123/transactions",
        fn conn ->
          response(conn, 200, %{
            "transactions" => [
              %{
                "id" => "TX-123",
                "status" => "COMPLETED",
                "payer_email" => "buyer@example.com",
                "amount_with_breakdown" => %{"currency_code" => "USD", "value" => "10.00"},
                "time" => "2026-08-01T00:00:00Z"
              }
            ],
            "total_items" => 1,
            "total_pages" => 1,
            "links" => []
          })
        end
      )

      assert {:ok, %Transactions{total_items: 1, transactions: [tx]}} =
               Subscription.transactions(
                 "I-123",
                 "2026-01-01T00:00:00Z",
                 "2026-08-01T00:00:00Z"
               )

      assert %Transaction{id: "TX-123", status: :completed} = tx

      assert %Transaction{id: "TX-1", status: :completed} =
               Transaction.cast(%{"id" => "TX-1", "status" => "COMPLETED"})
    end

    test "transactions list error", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/v1/billing/subscriptions/I-123/transactions",
        fn conn ->
          response(conn, 400, %{
            "name" => "INVALID_REQUEST",
            "message" => "Date range invalid",
            "debug_id" => "dbg-tx"
          })
        end
      )

      assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
               Subscription.transactions(
                 "I-123",
                 "2026-08-01T00:00:00Z",
                 "2026-01-01T00:00:00Z"
               )
    end

    test "Subscriber and BillingInfo subschemas" do
      assert Subscriber.changeset(%{
               "email_address" => "test@test.com",
               "payer_id" => "PAYER-1",
               "name" => %{"given_name" => "John", "surname" => "Doe"}
             }).valid?

      assert %BillingInfo{failed_payments_count: 2} =
               BillingInfo.cast(%{"failed_payments_count" => 2})
    end

    test "Subscription network error cases" do
      Application.put_env(:paypal, :url, "http://localhost:1")
      assert {:error, _} = Subscription.create(%{plan_id: "P-1"})
      assert {:error, _} = Subscription.show("I-1")
      assert {:error, _} = Subscription.update("I-1", [])
      assert {:error, _} = Subscription.revise("I-1", %{})
      assert {:error, _} = Subscription.suspend("I-1")
      assert {:error, _} = Subscription.cancel("I-1")
      assert {:error, _} = Subscription.activate("I-1")
      assert {:error, _} = Subscription.capture("I-1", %{})

      assert {:error, _} =
               Subscription.transactions("I-1", "2026-01-01T00:00:00Z", "2026-08-01T00:00:00Z")
    end
  end
end
