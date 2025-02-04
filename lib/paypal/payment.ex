defmodule Paypal.Payment do
  @moduledoc """
  Perform payment actions for Paypal. The payments are authorized orders.
  You can see further information via `Paypal.Order`.
  """
  use Tesla, only: [:get, :post], docs: false

  require Logger

  alias Paypal.Auth
  alias Paypal.Common.Error, as: PaymentError
  alias Paypal.Payment.Captured
  alias Paypal.Payment.Info
  alias Paypal.Payment.Refund
  alias Paypal.Payment.RefundRequest

  adapter({Tesla.Adapter.Finch, name: Paypal.Finch})

  plug(Tesla.Middleware.Logger,
    format: "$method /v2/payments$url ===> $status / time=$time",
    log_level: :debug
  )

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url) <> "/v2/payments")

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/json"},
    {"accept-language", "en_US"},
    {"authorization", "bearer #{Auth.get_token!()}"}
  ])

  plug(Tesla.Middleware.JSON)

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

  @spec refund(String.t(), RefundRequest.t() | map()) ::
          {:ok, Info.t()} | {:error, PaymentError.t() | String.t()}
  def(refund(id, body \\ %{})) do
    case post("/captures/#{id}/refund", body |> RefundRequest.cast() |> Jason.encode!()) do
      {:ok, %_{status: code, body: response}} when code in 200..299 ->
        {:ok, Refund.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
