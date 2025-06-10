defmodule Paypal.Payment do
  @moduledoc """
  Perform payment actions for Paypal. The payments are authorized orders.
  You can see further information via `Paypal.Order`.
  """
  require Logger

  alias Paypal.Auth
  alias Paypal.Common.Error, as: PaymentError
  alias Paypal.Payment.Captured
  alias Paypal.Payment.Info
  alias Paypal.Payment.Refund
  alias Paypal.Payment.RefundRequest

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      {Tesla.Middleware.Logger,
       format: "$method /v2/payments$url ===> $status / time=$time", log_level: :debug},
      {Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url) <> "/v2/payments"},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/json"},
         {"accept-language", "en_US"},
         {"authorization", "bearer #{Auth.get_token!()}"}
       ]},
      Tesla.Middleware.JSON
    ]
  end

  defp adapter do
    {Tesla.Adapter.Finch, name: Paypal.Finch}
  end

  defp get(uri), do: Tesla.get(client(), uri)
  defp post(uri, body), do: Tesla.post(client(), uri, body)

  @doc """
  Show information about the authorized order.
  """
  def show(id) do
    case get("/authorizations/#{id}") do
      {:ok, %_{status: 200, body: response}} ->
        {:ok, Info.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Void the authorized order. It's a way for cancel or return the blocked
  or authorized fonds.
  """
  def void(id) do
    case post("/authorizations/#{id}/void", "") do
      {:ok, %_{status: code, body: ""}} when code in 200..299 ->
        :ok

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Capture the authorized order. It's the final step to perform a payment with
  an authorized order.
  """
  def capture(id) do
    case post("/authorizations/#{id}/capture", "") do
      {:ok, %_{status: code, body: response}} when code in 200..299 ->
        {:ok, Captured.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Performs a refund of the capture that was captured previously.
  """
  def refund(id, body \\ %{}) do
    with {:ok, data} <- RefundRequest.changeset(body),
         {:ok, %_{status: code, body: response}} when code in 200..299 <-
           post("/captures/#{id}/refund", data) do
      {:ok, Refund.cast(response)}
    else
      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
