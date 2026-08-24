defmodule Paypal.Subscription.Plan do
  @moduledoc """
  Manage billing plans for PayPal Subscriptions.

  A billing plan defines the pricing, billing cycles, and payment preferences
  for a recurring subscription.

  Official PayPal API Documentation:
  [PayPal Billing Plans API v1](https://developer.paypal.com/docs/api/subscriptions/v1/#plans)
  """
  require Logger

  alias Paypal.Client
  alias Paypal.Common.Error, as: CommonError
  alias Paypal.Subscription.Plan.Create
  alias Paypal.Subscription.Plan.Info
  alias Paypal.Subscription.Plan.List, as: PlanList

  defp client, do: Client.new("/v1/billing/plans")

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
  Billing plan statuses:

  - `:created` - Plan created but not active.
  - `:inactive` - Plan inactive (cannot be used for new subscriptions).
  - `:active` - Plan active and ready for subscriptions.
  """
  @spec statuses() :: [created: String.t(), inactive: String.t(), active: String.t()]
  def statuses do
    [
      created: "CREATED",
      inactive: "INACTIVE",
      active: "ACTIVE"
    ]
  end

  @doc """
  Create a billing plan.

  Official documentation:
  [Create Plan](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_create)

  ## Examples

      iex> Paypal.Subscription.Plan.create(%{
      ...>   product_id: "PROD-123",
      ...>   name: "Monthly Premium Plan",
      ...>   description: "Monthly subscription plan",
      ...>   status: :active,
      ...>   billing_cycles: [
      ...>     %{
      ...>       frequency: %{"interval_unit" => "MONTH", "interval_count" => 1},
      ...>       tenure_type: :regular,
      ...>       sequence: 1,
      ...>       total_cycles: 0,
      ...>       pricing_scheme: %{"fixed_price" => %{"currency_code" => "USD", "value" => "10.00"}}
      ...>     }
      ...>   ],
      ...>   payment_preferences: %{
      ...>     auto_bill_outstanding: true,
      ...>     setup_fee_failure_action: :cancel,
      ...>     payment_failure_threshold: 3
      ...>   }
      ...> })
      {:ok, %Paypal.Subscription.Plan.Info{id: "P-123", ...}}

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
  List billing plans with optional filters.

  Official documentation:
  [List Plans](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_list)

  ## Options

    - `:product_id` - Filter by product ID.
    - `:plan_ids` - Filter by specific plan IDs (comma-separated).
    - `:page_size` - Number of items per page (1 to 20, default 10).
    - `:page` - Page number (default 1).
    - `:total_required` - Whether total items count is returned (`true` or `false`).

  """
  @spec list(keyword() | map()) :: {:ok, PlanList.t()} | {:error, CommonError.t() | term()}
  def list(opts \\ []) do
    case get("", opts) do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, PlanList.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Show billing plan details by plan ID.

  Official documentation:
  [Show Plan Details](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_get)
  """
  @spec show(String.t()) :: {:ok, Info.t()} | {:error, CommonError.t() | term()}
  def show(plan_id) do
    case get("/#{plan_id}", []) do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, Info.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Update a billing plan by ID using JSON Patch operations.

  Official documentation:
  [Update Plan](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_patch)
  """
  @spec update(String.t(), [map()]) :: :ok | {:error, CommonError.t() | term()}
  def update(plan_id, patch_operations) do
    case patch("/#{plan_id}", patch_operations) do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Activate a billing plan by ID.

  Official documentation:
  [Activate Plan](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_activate)
  """
  @spec activate(String.t()) :: :ok | {:error, CommonError.t() | term()}
  def activate(plan_id) do
    case post("/#{plan_id}/activate", "") do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Deactivate a billing plan by ID.

  Official documentation:
  [Deactivate Plan](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_deactivate)
  """
  @spec deactivate(String.t()) :: :ok | {:error, CommonError.t() | term()}
  def deactivate(plan_id) do
    case post("/#{plan_id}/deactivate", "") do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Update pricing schemes for a plan by ID.

  Official documentation:
  [Update Pricing Schemes](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_update-pricing-schemes)
  """
  @spec update_pricing_schemes(String.t(), map() | [map()]) ::
          :ok | {:error, CommonError.t() | term()}
  def update_pricing_schemes(plan_id, pricing_schemes) when is_list(pricing_schemes) do
    update_pricing_schemes(plan_id, %{"pricing_schemes" => pricing_schemes})
  end

  def update_pricing_schemes(plan_id, %{} = body) do
    case post("/#{plan_id}/update-pricing-schemes", body) do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
