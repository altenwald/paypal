defmodule Paypal.Payment do
  @moduledoc """
  Perform payment actions for PayPal. Payments are authorized orders or captures.

  Official PayPal API Documentation:
  [PayPal Payments API v2](https://developer.paypal.com/docs/api/payments/v2/)
  """

  alias Paypal.Client
  alias Paypal.Common.Error, as: PaymentError
  alias Paypal.Payment.Captured
  alias Paypal.Payment.Info
  alias Paypal.Payment.Refund
  alias Paypal.Payment.RefundRequest

  defp client, do: Client.new("/v2/payments")

  defp get(uri), do: Req.get(client(), url: uri)

  defp post(uri, body) when is_map(body) or is_list(body),
    do: Req.post(client(), url: uri, json: body)

  defp post(uri, body),
    do: Req.post(client(), url: uri, body: body)

  @doc """
  Show information about an authorized payment.

  Official documentation:
  [Show Details for Authorized Payment](https://developer.paypal.com/docs/api/payments/v2/#authorizations_get)
  """
  @spec show(String.t()) :: {:ok, Info.t()} | {:error, PaymentError.t() | term()}
  def show(id) do
    case get("/authorizations/#{id}") do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, Info.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Void an authorized payment. This cancels or releases the authorized funds.

  Official documentation:
  [Void Authorized Payment](https://developer.paypal.com/docs/api/payments/v2/#authorizations_void)
  """
  @spec void(String.t()) :: :ok | {:error, PaymentError.t() | term()}
  def void(id) do
    case post("/authorizations/#{id}/void", "") do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Capture an authorized payment.

  Official documentation:
  [Capture Authorized Payment](https://developer.paypal.com/docs/api/payments/v2/#authorizations_capture)
  """
  @spec capture(String.t()) :: {:ok, Captured.t()} | {:error, PaymentError.t() | term()}
  def capture(id) do
    case post("/authorizations/#{id}/capture", "") do
      {:ok, %Req.Response{status: code, body: response}}
      when code in 200..299 and is_map(response) ->
        {:ok, Captured.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Refund a captured payment by capture ID.

  Official documentation:
  [Refund Captured Payment](https://developer.paypal.com/docs/api/payments/v2/#captures_refund)
  """
  @spec refund(String.t(), map()) :: {:ok, Refund.t()} | {:error, PaymentError.t() | term()}
  def refund(id, body \\ %{}) do
    with {:ok, data} <- RefundRequest.changeset(body),
         {:ok, %Req.Response{status: code, body: response}}
         when code in 200..299 and is_map(response) <-
           post("/captures/#{id}/refund", data) do
      {:ok, Refund.cast(response)}
    else
      {:ok, %Req.Response{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
