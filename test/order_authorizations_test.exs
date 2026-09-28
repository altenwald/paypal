defmodule Paypal.OrderAuthorizationsTest do
  use Paypal.Case

  alias Paypal.Order
  alias Paypal.Order.Authorization
  alias Paypal.Order.PurchaseUnit.PaymentCollection

  # Same response shape as an authorized-then-captured production order.
  # All identifiers, dates and monetary values are fictional.
  defp payments do
    %{
      "authorizations" => [
        %{
          "id" => "TEST-AUTHORIZATION",
          "status" => "CAPTURED",
          "amount" => %{"currency_code" => "EUR", "value" => "20.00"},
          "seller_protection" => %{
            "status" => "ELIGIBLE",
            "dispute_categories" => ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"]
          },
          "expiration_time" => "2026-02-01T10:00:00Z",
          "create_time" => "2026-01-03T10:00:00Z",
          "update_time" => "2026-01-03T10:00:10Z",
          "links" => [
            %{
              "href" => "https://api.example.com/authorizations/TEST-AUTHORIZATION",
              "rel" => "self",
              "method" => "GET"
            }
          ]
        }
      ],
      "captures" => [
        %{
          "id" => "TEST-CAPTURE",
          "status" => "COMPLETED",
          "amount" => %{"currency_code" => "EUR", "value" => "20.00"},
          "final_capture" => true,
          "disbursement_mode" => "INSTANT",
          "seller_receivable_breakdown" => %{
            "gross_amount" => %{"currency_code" => "EUR", "value" => "20.00"},
            "paypal_fee" => %{"currency_code" => "EUR", "value" => "1.00"},
            "net_amount" => %{"currency_code" => "EUR", "value" => "19.00"}
          },
          "create_time" => "2026-01-03T10:00:10Z",
          "update_time" => "2026-01-03T10:00:10Z"
        }
      ]
    }
  end

  test "Order.show decodes authorizations alongside captures after capture" do
    expect_once("GET", "/v2/checkout/orders/TEST-ORDER", fn conn ->
      response(conn, 200, %{
        "id" => "TEST-ORDER",
        "status" => "COMPLETED",
        "intent" => "AUTHORIZE",
        "purchase_units" => [%{"reference_id" => "TEST-UNIT", "payments" => payments()}]
      })
    end)

    assert {:ok, %Order.Info{status: :completed, purchase_units: [unit]}} =
             Order.show("TEST-ORDER")

    assert [%Authorization{id: "TEST-AUTHORIZATION", status: :captured} = authorization] =
             unit.payments.authorizations

    assert authorization.amount.currency_code == "EUR"
    assert Decimal.equal?(authorization.amount.value, Decimal.new("20.00"))
    assert authorization.seller_protection.status == :eligible
    assert authorization.create_time == ~U[2026-01-03 10:00:00Z]
    assert [%{rel: "self"}] = authorization.links
    assert [capture] = unit.payments.captures
    assert capture.id == "TEST-CAPTURE"
    assert capture.disbursement_mode == :instant

    assert Decimal.equal?(
             capture.seller_receivable_breakdown.paypal_fee.value,
             Decimal.new("1.00")
           )

    assert Decimal.equal?(
             capture.seller_receivable_breakdown.net_amount.value,
             Decimal.new("19.00")
           )
  end

  test "PaymentCollection changeset casts authorization lists into typed structs" do
    changeset = PaymentCollection.changeset(payments())
    assert changeset.valid?
    collection = Ecto.Changeset.apply_changes(changeset)
    assert [%Authorization{status: :captured} = authorization] = collection.authorizations
    assert authorization.seller_protection.status == :eligible
    assert authorization.expiration_time == ~U[2026-02-01 10:00:00Z]
    assert [%{rel: "self"}] = authorization.links
    assert [%{id: "TEST-CAPTURE"}] = collection.captures
  end
end
