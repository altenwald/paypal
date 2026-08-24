defmodule Paypal.Subscription.ReviseResponse do
  @moduledoc """
  Response returned after revising a PayPal subscription.

  Official PayPal API Documentation:
  [Revise Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_revise)
  """
  use TypedEctoSchema

  alias Paypal.Common.Link

  @primary_key false

  @typedoc """
  Subscription revise response:

  - `plan_id` - Updated plan ID.
  - `quantity` - Updated quantity.
  - `plan_overridden` - Whether the plan was overridden.
  - `links` - HATEOAS links (e.g. approve link).
  """
  typed_embedded_schema do
    field(:plan_id, :string)
    field(:quantity, :string)
    field(:plan_overridden, :boolean, default: false)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
