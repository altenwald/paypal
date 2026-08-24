defmodule Paypal.Subscription.Capture do
  @moduledoc """
  Response returned after capturing an authorized payment on a subscription.

  Official PayPal API Documentation:
  [Capture Authorized Payment on Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_capture)
  """
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link

  @statuses [
    completed: "COMPLETED",
    declined: "DECLINED",
    pending: "PENDING",
    failed: "FAILED"
  ]

  @primary_key false

  @typedoc """
  Subscription capture response:

  - `id` - Capture ID.
  - `status` - Status of the capture (`:completed`, `:declined`, `:pending`, `:failed`).
  - `status_details` - Status details map if available.
  - `amount_with_breakdown` - Monetary amount with breakdown.
  - `create_time` - Date and time when the capture was created.
  - `update_time` - Date and time when the capture was last updated.
  - `links` - HATEOAS links.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:status, Ecto.Enum, values: @statuses)
    field(:status_details, :map)
    embeds_one(:amount_with_breakdown, CurrencyValue)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
