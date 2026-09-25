defmodule Paypal.Order do
  @moduledoc """
  The orders is the element that let us to charge an amount to the clients.

  We have two ways to proceed, it's called the `intent` and depending on what
  you choose, it will let you charge the money instantly or hold the money
  until the process, product or service will be released.

  - `capture` is the intent that charges the money immediately. The flow is:
    1. Create the order using `capture` as the intent, see `create/3`.
    2. Use the URL inside of the response for approving the payment.
    3. Capture the money, see `capture/1`.

  - `authorize` is the intent that holds the money and lets you capture
    the funds later. The flow is:
    1. Create the order using `authorize` as the intent, see `create/3`.
    2. Use the URL inside of the response for approving the payment.
    3. Create the authorization, see `authorize/1`.
    4. Capture funds using the authorization, see `Paypal.Payment.capture/1`.

  If you are interested in the authorization, check `Paypal.Payment` module for
  further information.

  Official PayPal API Documentation:
  [PayPal Orders API v2](https://developer.paypal.com/docs/api/orders/v2/)
  """

  alias Paypal.Client
  alias Paypal.Common.Error, as: OrderError
  alias Paypal.Order.Authorized
  alias Paypal.Order.Create
  alias Paypal.Order.ExperienceContext
  alias Paypal.Order.Info
  alias Paypal.Order.PurchaseUnit

  defp client, do: Client.new("/v2/checkout")

  defp get(uri), do: Req.get(client(), url: uri)

  defp post(uri, body) when is_map(body) or is_list(body),
    do: Req.post(client(), url: uri, json: body)

  defp post(uri, body),
    do: Req.post(client(), url: uri, body: body)

  @doc """
  Statuses for the order. The order is following different states, we could
  illustrate it as a state diagram:

  ```mermaid
  stateDiagram-v2
      [*] --> CREATED
      CREATED --> PAYER_ACTION_REQUIRED
      PAYER_ACTION_REQUIRED --> APPROVED
      APPROVED --> SAVED
      SAVED --> APPROVED
      APPROVED --> VOIDED
      APPROVED --> COMPLETED
      VOIDED --> [*]
      COMPLETED --> [*]
  ```

  As you can see, we start in CREATED state and we are moving until reach
  VOIDED or COMPLETED.
  """
  @spec statuses() :: [
          created: String.t(),
          saved: String.t(),
          approved: String.t(),
          voided: String.t(),
          completed: String.t(),
          payer_action_required: String.t()
        ]
  def statuses do
    [
      created: "CREATED",
      saved: "SAVED",
      approved: "APPROVED",
      voided: "VOIDED",
      completed: "COMPLETED",
      payer_action_required: "PAYER_ACTION_REQUIRED"
    ]
  end

  @doc """
  The kind of intents, for further information `Paypal.Order`.
  """
  @spec intents() :: [capture: String.t(), authorize: String.t()]
  def intents do
    [
      capture: "CAPTURE",
      authorize: "AUTHORIZE"
    ]
  end

  @doc """
  Create an order.

  Official documentation:
  [Create Order](https://developer.paypal.com/docs/api/orders/v2/#orders_create)
  """
  @spec create(:capture | :authorize, [PurchaseUnit.t() | map()], ExperienceContext.t() | map()) ::
          {:ok, Info.t()} | {:error, OrderError.t() | term()}
  def create(intent, purchase_units, experience_context) do
    with {:ok, data} <- Create.changeset(%{intent: intent, purchase_units: purchase_units}),
         {:ok, context} <- ExperienceContext.changeset(experience_context),
         data = add_experience_context(data, context),
         {:ok, %Req.Response{status: code, body: response}}
         when code in 200..299 and is_map(response) <-
           post("/orders", data) do
      {:ok, Info.cast(response)}
    else
      {:ok, %Req.Response{body: response}} ->
        {:error, OrderError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  defp add_experience_context(data, context) do
    data
    |> Map.put("payment_source", %{
      "paypal" => %{
        "experience_context" => context
      }
    })
  end

  @doc """
  Show order details by ID.

  Official documentation:
  [Show Order Details](https://developer.paypal.com/docs/api/orders/v2/#orders_get)
  """
  @spec show(String.t()) :: {:ok, Info.t()} | {:error, OrderError.t() | term()}
  def show(id) do
    case get("/orders/#{id}") do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, Info.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, OrderError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Capture payment for an order.

  Official documentation:
  [Capture Payment for Order](https://developer.paypal.com/docs/api/orders/v2/#orders_capture)
  """
  @spec capture(String.t()) :: {:ok, Info.t()} | {:error, OrderError.t() | term()}
  def capture(id) do
    case post("/orders/#{id}/capture", "") do
      {:ok, %Req.Response{status: code, body: response}}
      when code in 200..299 and is_map(response) ->
        {:ok, Info.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, OrderError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Authorize payment for an order.

  Official documentation:
  [Authorize Payment for Order](https://developer.paypal.com/docs/api/orders/v2/#orders_authorize)
  """
  @spec authorize(String.t()) :: {:ok, Authorized.t()} | {:error, OrderError.t() | term()}
  def authorize(id) do
    case post("/orders/#{id}/authorize", "") do
      {:ok, %Req.Response{status: code, body: response}}
      when code in 200..299 and is_map(response) ->
        {:ok, Authorized.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, OrderError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
