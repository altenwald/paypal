defmodule Paypal.Payment do
  use Tesla, only: [:get, :post], docs: false

  require Logger

  alias Paypal.Auth
  alias Paypal.Common.Error, as: PaymentError
  alias Paypal.Payment.Info

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

  def capture(id) do
    case post("/authorizations/#{id}/capture", "") do
      {:ok, %_{status: code, body: response}} when code in 200..299 ->
        {:ok, response}

      {:ok, %_{body: response}} ->
        {:error, PaymentError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
