defmodule Paypal.Order.Info do
  @moduledoc """
  Order information. The information retrieved from Paypal about the order.
  """
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Order
  alias Paypal.Order.Payer
  alias Paypal.Order.PurchaseUnit

  @primary_key false

  @typedoc """
  The information for the order containing:

  - `id` is the ID for the order.
  - `create_time` is the date and time when the order was created.
  - `intent` could be `capture` or `authorize`.
  - `links` are the HATEOAS about the following valid actions.
  - `purchase_units` are the units inside of the order.
  - `status` for the order.
  - `payment_source` is a map that should contains the information about
    how the payment was made. If that was using PayPal credit, or card,
    or whatever else.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:intent, Ecto.Enum, values: Order.intents())
    field(:status, Ecto.Enum, values: Order.statuses())
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
    embeds_many(:purchase_units, PurchaseUnit)
    embeds_one(:payer, Payer)
    #  TODO
    field(:payment_source, :map)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
