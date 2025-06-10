defmodule Paypal.Order do
  @moduledoc """
  The orders is the element that let us to charge an amount to the clients.

  We have to ways to proceed, it's called the `intent` and depending on what
  you choose, it will let you charge the money instantly or hold the money
  until the process, product or service will be released.

  - `capture` is the intent that charge the money immediately. The flow is:
    1. Crete the order using `capture` as the intent, see `create/2`.
    2. Use the URL inside of the response for approving the payment.
    3. Capture the money, see `capture/1`.

  - `authorize` is the intent that hold the money and it will let you capture
    the fonds later. The flow is:
    1. Create the order using `authorize` as the intent, see `create/2`.
    2. Use the URL inside of the response for approving the payment.
    3. Create the authorization, see `authorize/1`.
    4. Capture fonds using the authorization, see `Paypal.Payment.capture/1`.

  If you are interested on the authorization, check `Paypal.Payment` module for
  further information.
  """
  require Logger

  alias Paypal.Auth
  alias Paypal.Common.Error, as: OrderError
  alias Paypal.Order.Authorized
  alias Paypal.Order.Create
  alias Paypal.Order.ExperienceContext
  alias Paypal.Order.Info
  alias Paypal.Order.PurchaseUnit

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      {Tesla.Middleware.Logger,
       format: "$method /v2/checkout$url ===> $status / time=$time", log_level: :debug},
      {Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url) <> "/v2/checkout"},
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
  def intents do
    [
      capture: "CAPTURE",
      authorize: "AUTHORIZE"
    ]
  end

  @doc """
  Create an order.
  """
  @spec create(:capture | :authorize, [PurchaseUnit.t() | map()], ExperienceContext.t() | map()) ::
          {:ok, Info.t()} | {:error, OrderError.t() | String.t()}
  def create(intent, purchase_units, experience_context) do
    with {:ok, data} <- Create.changeset(%{intent: intent, purchase_units: purchase_units}),
         {:ok, context} <- ExperienceContext.changeset(experience_context),
         data = add_experience_context(data, context),
         {:ok, %_{status: code, body: response}} when code in 200..299 <- post("/orders", data) do
      {:ok, Info.cast(response)}
    else
      {:ok, %_{body: response}} ->
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

  def show(id) do
    case get("/orders/#{id}") do
      {:ok, %_{status: 200, body: response}} ->
        {:ok, Info.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, OrderError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  def capture(id) do
    case post("/orders/#{id}/capture", "") do
      {:ok, %_{status: code, body: response}} when code in 200..299 ->
        {:ok, Info.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, OrderError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  def authorize(id) do
    case post("/orders/#{id}/authorize", "") do
      {:ok, %_{status: code, body: response}} when code in 200..299 ->
        {:ok, Authorized.cast(response)}

      {:ok, %_{body: response}} ->
        {:error, OrderError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
