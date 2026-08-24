defmodule Paypal.Subscription.Plan.Info do
  @moduledoc """
  Plan details retrieved from the PayPal Billing Plans API.

  Official PayPal API Documentation:
  [PayPal Billing Plans API](https://developer.paypal.com/docs/api/subscriptions/v1/#plans)
  """
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Subscription.Plan
  alias Paypal.Subscription.Plan.BillingCycle
  alias Paypal.Subscription.Plan.PaymentPreferences
  alias Paypal.Subscription.Plan.Taxes

  @primary_key false

  @typedoc """
  Billing plan details:

  - `id` - The unique plan ID (e.g. `P-5ML4271244454362WXNWU5NQ`).
  - `product_id` - The ID of the catalog product.
  - `name` - The plan name.
  - `status` - The plan status (`:created`, `:inactive`, `:active`).
  - `description` - Description of the plan.
  - `usage_type` - Usage type (e.g. "LICENSED").
  - `billing_cycles` - List of billing cycles configured.
  - `payment_preferences` - Payment preferences.
  - `taxes` - Tax settings.
  - `quantity_supported` - Whether the plan supports quantity.
  - `create_time` - Date and time when the plan was created.
  - `update_time` - Date and time when the plan was last updated.
  - `links` - HATEOAS links.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:product_id, :string)
    field(:name, :string)
    field(:status, Ecto.Enum, values: Plan.statuses())
    field(:description, :string)
    field(:usage_type, :string)
    embeds_many(:billing_cycles, BillingCycle)
    embeds_one(:payment_preferences, PaymentPreferences)
    embeds_one(:taxes, Taxes)
    field(:quantity_supported, :boolean)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
