defmodule Paypal.OrderTest do
  use Paypal.Case

  alias Paypal.Order
  alias Paypal.Order.Authorized
  alias Paypal.Order.Create
  alias Paypal.Order.ExperienceContext
  alias Paypal.Order.PurchaseUnit
  alias Paypal.Order.PurchaseUnit.Capture, as: UnitCapture
  alias Paypal.Order.PurchaseUnit.Item
  alias Paypal.Order.PurchaseUnit.PaymentCollection
  alias Paypal.Order.UpcCode

  test "Order statuses and intents" do
    assert :created in Keyword.keys(Order.statuses())
    assert :capture in Keyword.keys(Order.intents())
  end

  test "Order.Create changeset validations" do
    assert {:error, %{intent: _}} = Create.changeset(%{})
    assert {:error, %{purchase_units: _}} = Create.changeset(%{intent: :capture})
  end

  test "ExperienceContext changeset validations" do
    assert {:error, %{return_url: _, cancel_url: _}} = ExperienceContext.changeset(%{})

    assert {:ok, context} =
             ExperienceContext.changeset(%{
               "return_url" => "https://return.com",
               "cancel_url" => "https://cancel.com",
               "brand_name" => "Brand",
               "user_action" => :continue
             })

    assert context[:brand_name] == "Brand" || context["brand_name"] == "Brand"
  end

  test "UpcCode and PurchaseUnit.Item validation" do
    assert UpcCode.changeset(%{"type" => "UPC-A", "code" => "12345678"}).valid?
    refute UpcCode.changeset(%{"type" => "UPC-A", "code" => "123"}).valid?

    assert Item.changeset(%{
             "name" => "Product",
             "quantity" => 1,
             "description" => "A test item",
             "sku" => "SKU-1",
             "category" => "PHYSICAL_GOODS",
             "unit_amount" => %{"currency_code" => "EUR", "value" => "10.00"},
             "tax" => %{"currency_code" => "EUR", "value" => "2.10"},
             "upc" => %{"type" => "UPC-A", "code" => "12345678"}
           }).valid?

    refute Item.changeset(%{"name" => "Product"}).valid?
  end

  test "Authorized schemas, SellerProtection, PaymentCollection, UnitCapture" do
    assert UnitCapture.changeset(%UnitCapture{}, %{
             "id" => "CAP-1",
             "status" => "COMPLETED",
             "amount" => %{"currency_code" => "USD", "value" => "10.00"}
           }).valid?

    assert PaymentCollection.changeset(%PaymentCollection{}, %{
             "captures" => [
               %{
                 "id" => "CAP-1",
                 "status" => "COMPLETED",
                 "amount" => %{"currency_code" => "USD", "value" => "10.00"}
               }
             ]
           }).valid?

    assert %Authorized{id: "ORD-1", status: :completed} =
             Authorized.cast(%{
               "id" => "ORD-1",
               "status" => "COMPLETED",
               "intent" => "AUTHORIZE",
               "purchase_units" => [
                 %{
                   "reference_id" => "REF-1",
                   "payments" => %{
                     "authorizations" => [
                       %{
                         "id" => "AUTH-1",
                         "status" => "CREATED",
                         "amount" => %{"currency_code" => "USD", "value" => "10.00"},
                         "seller_protection" => %{
                           "status" => "ELIGIBLE",
                           "dispute_categories" => ["ITEM_NOT_RECEIVED"]
                         }
                       }
                     ],
                     "captures" => [
                       %{
                         "id" => "CAP-1",
                         "status" => "COMPLETED",
                         "amount" => %{"currency_code" => "USD", "value" => "10.00"}
                       }
                     ]
                   }
                 }
               ]
             })
  end

  test "Order.create returns error on API failure", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v2/checkout/orders", fn conn ->
      response(conn, 400, %{
        "name" => "INVALID_REQUEST",
        "message" => "Validation error",
        "debug_id" => "dbg-001"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "INVALID_REQUEST"}} =
             Order.create(
               :capture,
               [%{"amount" => %{"currency_code" => "EUR", "value" => "10.00"}}],
               %{"return_url" => "https://return.com", "cancel_url" => "https://cancel.com"}
             )
  end

  test "Order.show returns error on 404", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/v2/checkout/orders/non-existent", fn conn ->
      response(conn, 404, %{
        "name" => "RESOURCE_NOT_FOUND",
        "message" => "Order not found",
        "debug_id" => "dbg-404"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "RESOURCE_NOT_FOUND"}} =
             Order.show("non-existent")
  end

  test "Order.capture returns error on API failure", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v2/checkout/orders/ORD-123/capture", fn conn ->
      response(conn, 422, %{
        "name" => "UNPROCESSABLE_ENTITY",
        "message" => "Cannot capture order",
        "debug_id" => "dbg-422"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
             Order.capture("ORD-123")
  end

  test "Order.authorize returns error on API failure", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v2/checkout/orders/ORD-123/authorize", fn conn ->
      response(conn, 422, %{
        "name" => "UNPROCESSABLE_ENTITY",
        "message" => "Cannot authorize order",
        "debug_id" => "dbg-422"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
             Order.authorize("ORD-123")
  end

  test "PurchaseUnit validation limits" do
    refute PurchaseUnit.changeset(%{
             "reference_id" => String.duplicate("a", 300),
             "amount" => %{"currency_code" => "EUR", "value" => "10.00"}
           }).valid?
  end

  test "Order network error cases" do
    Application.put_env(:paypal, :url, "http://localhost:1")
    assert {:error, _} = Order.show("ORD-1")
    assert {:error, _} = Order.capture("ORD-1")
    assert {:error, _} = Order.authorize("ORD-1")

    assert {:error, _} =
             Order.create(
               :capture,
               [%{"amount" => %{"currency_code" => "EUR", "value" => "10.00"}}],
               %{"return_url" => "https://return.com", "cancel_url" => "https://cancel.com"}
             )
  end
end
