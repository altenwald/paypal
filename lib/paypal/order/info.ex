defmodule Paypal.Order.Info do
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Order
  alias Paypal.Order.PurchaseUnit

  @primary_key false

  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:create_time, :utc_datetime)
    field(:intent, Ecto.Enum, values: Order.intents())
    embeds_many(:links, Link)
    embeds_many(:purchase_units, PurchaseUnit)
    field(:status, Ecto.Enum, values: Order.statuses())
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
