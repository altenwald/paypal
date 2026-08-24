defmodule Paypal.Subscription.Info do
  @moduledoc """
  Subscription information retrieved from the PayPal Subscriptions API.

  Official PayPal API Documentation:
  [Show Subscription Details](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_get)
  """
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link
  alias Paypal.Subscription
  alias Paypal.Subscription.BillingInfo
  alias Paypal.Subscription.Plan.Info, as: PlanInfo
  alias Paypal.Subscription.Subscriber

  @primary_key false

  @typedoc """
  Subscription details:

  - `id` - The unique subscription ID (e.g. `I-BW452GLLEP1G`).
  - `plan_id` - The ID of the billing plan.
  - `start_time` - Date and time when the subscription starts.
  - `quantity` - The subscription quantity.
  - `shipping_amount` - The shipping amount for the subscription.
  - `subscriber` - Information about the subscriber.
  - `billing_info` - Billing details and cycle executions.
  - `create_time` - Date and time when the subscription was created.
  - `update_time` - Date and time when the subscription was last updated.
  - `custom_id` - Custom ID provided by the API caller.
  - `plan_overridden` - Whether the plan was overridden.
  - `plan` - Embedded plan details if requested with `?fields=plan`.
  - `status` - The subscription status (`:approval_pending`, `:approved`, `:active`, `:suspended`, `:cancelled`, `:expired`).
  - `status_change_note` - Note explaining reason for last status change.
  - `status_update_time` - Date and time of last status change.
  - `links` - HATEOAS links.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:plan_id, :string)
    field(:start_time, :utc_datetime)
    field(:quantity, :string)
    embeds_one(:shipping_amount, CurrencyValue)
    embeds_one(:subscriber, Subscriber)
    embeds_one(:billing_info, BillingInfo)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    field(:custom_id, :string)
    field(:plan_overridden, :boolean, default: false)
    embeds_one(:plan, PlanInfo)
    field(:status, Ecto.Enum, values: Subscription.statuses())
    field(:status_change_note, :string)
    field(:status_update_time, :utc_datetime)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
