defmodule Paypal.PaymentTest do
  use Paypal.Case

  alias Paypal.Payment
  alias Paypal.Payment.Refund
  alias Paypal.Payment.RefundRequest

  test "Payment.show returns error on 404", %{bypass: bypass} do
    Passby.expect_once(bypass, "GET", "/v2/payments/authorizations/non-existent", fn conn ->
      response(conn, 404, %{
        "name" => "RESOURCE_NOT_FOUND",
        "message" => "Authorization not found",
        "debug_id" => "dbg-404"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "RESOURCE_NOT_FOUND"}} =
             Payment.show("non-existent")
  end

  test "Payment.void returns error on 422", %{bypass: bypass} do
    Passby.expect_once(bypass, "POST", "/v2/payments/authorizations/auth-123/void", fn conn ->
      response(conn, 422, %{
        "name" => "UNPROCESSABLE_ENTITY",
        "message" => "Cannot void authorization",
        "debug_id" => "dbg-422"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
             Payment.void("auth-123")
  end

  test "Payment.capture returns error on 422", %{bypass: bypass} do
    Passby.expect_once(bypass, "POST", "/v2/payments/authorizations/auth-123/capture", fn conn ->
      response(conn, 422, %{
        "name" => "UNPROCESSABLE_ENTITY",
        "message" => "Cannot capture authorization",
        "debug_id" => "dbg-422"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
             Payment.capture("auth-123")
  end

  test "Payment.refund returns error on 422", %{bypass: bypass} do
    Passby.expect_once(bypass, "POST", "/v2/payments/captures/cap-123/refund", fn conn ->
      response(conn, 422, %{
        "name" => "UNPROCESSABLE_ENTITY",
        "message" => "Cannot refund capture",
        "debug_id" => "dbg-422"
      })
    end)

    assert {:error, %Paypal.Common.Error{name: "UNPROCESSABLE_ENTITY"}} =
             Payment.refund("cap-123", %{
               "amount" => %{"currency_code" => "USD", "value" => "10.00"},
               "note_to_payer" => "Defective item"
             })
  end

  test "Payment.refund returns error on invalid changeset" do
    assert {:error, %{amount: _}} =
             Payment.refund("cap-123", %{
               "amount" => %{"currency_code" => "INVALID", "value" => "10.00"}
             })
  end

  test "Payment.RefundRequest and Refund changeset" do
    assert {:ok, data} =
             RefundRequest.changeset(%{
               "amount" => %{"currency_code" => "USD", "value" => "5.00"},
               "note_to_payer" => "Partial refund",
               "invoice_id" => "INV-1"
             })

    assert data[:note_to_payer] == "Partial refund" || data["note_to_payer"] == "Partial refund"

    refund_data = %{
      "id" => "REF-123",
      "status" => "COMPLETED",
      "amount" => %{"currency_code" => "USD", "value" => "5.00"}
    }

    assert %Refund{id: "REF-123", status: :completed} = Refund.cast(refund_data)
    assert Refund.changeset(refund_data).valid?
  end

  test "Payment network error cases" do
    Application.put_env(:paypal, :url, "http://localhost:1")
    assert {:error, _} = Payment.show("auth-1")
    assert {:error, _} = Payment.void("auth-1")
    assert {:error, _} = Payment.capture("auth-1")

    assert {:error, _} =
             Payment.refund("cap-1", %{"amount" => %{"currency_code" => "USD", "value" => "5.00"}})
  end
end
