defmodule Paypal.Subscription do
  @moduledoc """
  Manage recurring billing subscriptions for PayPal.

  The PayPal Subscriptions API allows you to create and manage subscriptions,
  handle subscriber lifecycles (suspend, cancel, activate, revise), capture
  outstanding balances, and list subscription transactions.

  Official PayPal API Documentation:
  [PayPal Subscriptions API v1](https://developer.paypal.com/docs/api/subscriptions/v1/)

  ## Subscription Lifecycle

  ```mermaid
  stateDiagram-v2
      [*] --> APPROVAL_PENDING
      APPROVAL_PENDING --> APPROVED
      APPROVAL_PENDING --> CANCELLED
      APPROVED --> ACTIVE
      APPROVED --> CANCELLED
      ACTIVE --> SUSPENDED
      SUSPENDED --> ACTIVE
      ACTIVE --> CANCELLED
      ACTIVE --> EXPIRED
      SUSPENDED --> CANCELLED
      SUSPENDED --> EXPIRED
      CANCELLED --> [*]
      EXPIRED --> [*]
  ```

  ## Modules

  - `Paypal.Subscription.Product` - Catalog Products management.
  - `Paypal.Subscription.Plan` - Billing Plans management.
  """

  alias Paypal.Client
  alias Paypal.Common.Error, as: CommonError
  alias Paypal.Subscription.Capture
  alias Paypal.Subscription.Create
  alias Paypal.Subscription.Info
  alias Paypal.Subscription.ReviseResponse
  alias Paypal.Subscription.Transactions

  defp client, do: Client.new("/v1/billing/subscriptions")

  defp get(uri, opts) do
    query =
      opts
      |> Keyword.get(:query, opts)
      |> Enum.into([])
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    Req.get(client(), url: uri, params: query)
  end

  defp post(uri, body) when is_map(body) or is_list(body),
    do: Req.post(client(), url: uri, json: body)

  defp post(uri, body),
    do: Req.post(client(), url: uri, body: body)

  defp patch(uri, body) when is_map(body) or is_list(body),
    do: Req.patch(client(), url: uri, json: body)

  defp patch(uri, body),
    do: Req.patch(client(), url: uri, body: body)

  @doc """
  Returns the list of valid subscription statuses:

  - `:approval_pending` - Subscription created, awaiting buyer approval.
  - `:approved` - Buyer approved subscription.
  - `:active` - Subscription is active and billing.
  - `:suspended` - Subscription is suspended.
  - `:cancelled` - Subscription has been cancelled.
  - `:expired` - Subscription reached its end date.
  """
  @spec statuses() :: [
          approval_pending: String.t(),
          approved: String.t(),
          active: String.t(),
          suspended: String.t(),
          cancelled: String.t(),
          expired: String.t()
        ]
  def statuses do
    [
      approval_pending: "APPROVAL_PENDING",
      approved: "APPROVED",
      active: "ACTIVE",
      suspended: "SUSPENDED",
      cancelled: "CANCELLED",
      expired: "EXPIRED"
    ]
  end

  @doc """
  Create a subscription.

  Official documentation:
  [Create Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_create)

  ## Examples

      iex> Paypal.Subscription.create(%{
      ...>   plan_id: "P-5ML4271244454362WXNWU5NQ",
      ...>   start_time: "2026-09-01T00:00:00Z",
      ...>   subscriber: %{
      ...>     name: %{given_name: "John", surname: "Doe"},
      ...>     email_address: "buyer@example.com"
      ...>   },
      ...>   application_context: %{
      ...>     brand_name: "My SaaS",
      ...>     locale: "en-US",
      ...>     return_url: "https://example.com/return",
      ...>     cancel_url: "https://example.com/cancel"
      ...>   }
      ...> })
      {:ok, %Paypal.Subscription.Info{id: "I-BW452GLLEP1G", ...}}

  """
  @spec create(map()) :: {:ok, Info.t()} | {:error, CommonError.t() | term()}
  def create(params) do
    with {:ok, data} <- Create.changeset(params),
         {:ok, %Req.Response{status: code, body: response}}
         when code in 200..299 and is_map(response) <-
           post("", data) do
      {:ok, Info.cast(response)}
    else
      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Show subscription details by ID.

  Official documentation:
  [Show Subscription Details](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_get)

  ## Options

    - `:fields` - Pass `"plan"` to include plan details in response.

  """
  @spec show(String.t(), keyword() | map()) ::
          {:ok, Info.t()} | {:error, CommonError.t() | term()}
  def show(id, opts \\ []) do
    case get("/#{id}", opts) do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, Info.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Update a subscription by ID using JSON Patch operations.

  Official documentation:
  [Update Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_patch)
  """
  @spec update(String.t(), [map()]) :: :ok | {:error, CommonError.t() | term()}
  def update(id, patch_operations) do
    case patch("/#{id}", patch_operations) do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Revise plan or quantity for a subscription.

  Official documentation:
  [Revise Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_revise)
  """
  @spec revise(String.t(), map()) ::
          {:ok, ReviseResponse.t()} | {:error, CommonError.t() | term()}
  def revise(id, params) do
    case post("/#{id}/revise", params) do
      {:ok, %Req.Response{status: code, body: response}}
      when code in 200..299 and is_map(response) ->
        {:ok, ReviseResponse.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Suspend a subscription by ID.

  Official documentation:
  [Suspend Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_suspend)
  """
  @spec suspend(String.t(), String.t()) :: :ok | {:error, CommonError.t() | term()}
  def suspend(id, reason \\ "") do
    case post("/#{id}/suspend", %{"reason" => reason}) do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Cancel a subscription by ID.

  Official documentation:
  [Cancel Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_cancel)
  """
  @spec cancel(String.t(), String.t()) :: :ok | {:error, CommonError.t() | term()}
  def cancel(id, reason \\ "") do
    case post("/#{id}/cancel", %{"reason" => reason}) do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Activate a subscription by ID.

  Official documentation:
  [Activate Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_activate)
  """
  @spec activate(String.t(), String.t()) :: :ok | {:error, CommonError.t() | term()}
  def activate(id, reason \\ "") do
    case post("/#{id}/activate", %{"reason" => reason}) do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Capture an authorized payment on a subscription.

  Official documentation:
  [Capture Authorized Payment](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_capture)

  ## Examples

      iex> Paypal.Subscription.capture("I-BW452GLLEP1G", %{
      ...>   note: "Charging outstanding balance",
      ...>   capture_type: "OUTSTANDING_BALANCE",
      ...>   amount: %{currency_code: "USD", value: "10.00"}
      ...> })
      {:ok, %Paypal.Subscription.Capture{id: "CAP-123", ...}}

  """
  @spec capture(String.t(), map()) :: {:ok, Capture.t()} | {:error, CommonError.t() | term()}
  def capture(id, params) do
    case post("/#{id}/capture", params) do
      {:ok, %Req.Response{status: code, body: response}}
      when code in 200..299 and is_map(response) ->
        {:ok, Capture.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  List transactions for a subscription within a date range.

  Official documentation:
  [List Transactions for Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_transactions)

  ## Parameters

    - `id` - The subscription ID.
    - `start_time` - Start date-time filter (ISO 8601 string, e.g. "2026-01-01T00:00:00Z").
    - `end_time` - End date-time filter (ISO 8601 string, e.g. "2026-08-01T00:00:00Z").

  """
  @spec transactions(String.t(), String.t(), String.t()) ::
          {:ok, Transactions.t()} | {:error, CommonError.t() | term()}
  def transactions(id, start_time, end_time) do
    case get("/#{id}/transactions", start_time: start_time, end_time: end_time) do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, Transactions.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
