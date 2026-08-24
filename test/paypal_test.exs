defmodule Paypal.PaypalTest do
  use Paypal.Case

  alias Paypal.Auth
  alias Paypal.Auth.Access
  alias Paypal.Auth.Request, as: AuthRequest
  alias Paypal.Auth.Worker, as: AuthWorker
  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Error, as: CommonError
  alias Paypal.Common.Link
  alias Paypal.Common.Operation
  alias Paypal.EctoHelpers

  test "Paypal.Auth.get_token! raises when no token is available" do
    clear_token()

    assert {:error, :notfound} == Auth.get_token()
    assert_raise MatchError, fn -> Auth.get_token!() end
  end

  test "Paypal.Auth.Worker handle_continue with error", %{bypass: bypass} do
    clear_token()

    Bypass.expect(bypass, "POST", "/v1/oauth2/token", fn conn ->
      Plug.Conn.resp(conn, 500, "Internal Server Error")
    end)

    if pid = Process.whereis(AuthWorker) do
      send(pid, :refresh)
      Process.sleep(50)
    end

    assert {:error, :notfound} == Auth.get_token()
  end

  test "Paypal.Auth.Access cast" do
    valid_data = %{
      "access_token" => "TOK",
      "token_type" => "Bearer",
      "app_id" => "APP",
      "expires_in" => 3600,
      "nonce" => "N",
      "scope" => "https://uri.paypal.com/services/subscriptions"
    }

    assert {:ok, %Access{access_token: "TOK"}} = Access.cast(valid_data)
    assert {:error, _} = Access.cast(%{"invalid" => true})
  end

  test "Paypal.Auth.Request error connection" do
    Application.put_env(:paypal, :url, "http://localhost:1")
    assert {:error, _} = AuthRequest.auth()
  end

  test "Paypal.Common.Error casting" do
    data = %{
      "debug_id" => "dbg-12345",
      "name" => "INVALID_REQUEST",
      "message" => "Request is not well-formed",
      "details" => [
        %{
          "field" => "/intent",
          "value" => "INVALID",
          "location" => "body",
          "issue" => "INVALID_PARAMETER_VALUE",
          "description" => "The value of a field is invalid"
        }
      ],
      "links" => [
        %{
          "href" =>
            "https://developer.paypal.com/docs/api/orders/v2/#error-INVALID_PARAMETER_VALUE",
          "rel" => "information_link",
          "method" => "GET"
        }
      ]
    }

    error = CommonError.cast(data)
    assert error.debug_id == "dbg-12345"
    assert error.name == "INVALID_REQUEST"
    assert error.message == "Request is not well-formed"
    assert length(error.details) == 1
    detail = hd(error.details)
    assert detail.field == "/intent"
    assert detail.value == "INVALID"
    assert detail.issue == "INVALID_PARAMETER_VALUE"
    assert length(error.links) == 1
    assert hd(error.links).rel == "information_link"

    # Test binary and fallback error casting
    assert %CommonError{message: "Error string"} = CommonError.cast("Error string")
    assert %CommonError{} = CommonError.cast(nil)
  end

  test "Paypal.Common.Operation casting" do
    data = %{
      "id" => "OP-123",
      "status" => "COMPLETED",
      "links" => [
        %{
          "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/OP-123",
          "rel" => "self",
          "method" => "GET"
        }
      ]
    }

    op = Operation.cast(data)
    assert op.id == "OP-123"
    assert op.status == :completed
    assert length(op.links) == 1
  end

  test "Paypal.Common.Link casting" do
    data = %{
      "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/123",
      "rel" => "self",
      "method" => "POST",
      "encType" => "application/json"
    }

    link = Link.cast(data)
    assert link.href == "https://api.sandbox.paypal.com/v2/checkout/orders/123"
    assert link.rel == "self"
    assert link.method == :post
    assert link.enc_type == "application/json"
  end

  test "Paypal.Common.CurrencyValue changeset and validation" do
    assert CurrencyValue.changeset(%{"currency_code" => "USD", "value" => "10.00"}).valid?

    changeset = CurrencyValue.changeset(%{"currency_code" => "US", "value" => "10.00"})
    refute changeset.valid?

    changeset2 = CurrencyValue.changeset(%{"currency_code" => "USD"})
    refute changeset2.valid?
  end

  test "Paypal.EctoHelpers clean_data and traverse_errors" do
    assert %{"a" => "b", "c" => %{"d" => "e"}} ==
             EctoHelpers.clean_data(%{
               "a" => "b",
               "nil_val" => nil,
               "empty_list" => [],
               "c" => %{"d" => "e", "nil_nested" => nil}
             })

    assert ["a", "b"] == EctoHelpers.clean_data(["a", nil, "b", []])
    assert 42 == EctoHelpers.clean_data(42)
  end
end
