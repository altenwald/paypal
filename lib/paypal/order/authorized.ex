defmodule Paypal.Order.Authorized do
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Order
  alias Paypal.Order.Authorization

  @primary_key false

  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:status, Ecto.Enum, values: Order.statuses(), embed_as: :dumped)
    # TODO
    field(:payment_source, :map)

    embeds_many :purchase_units, PurchaseUnit, primary_key: false do
      field(:reference_id, :string, primary_key: true)

      embeds_one :payments, Payment, primary_key: false do
        embeds_many(:authorizations, Authorization)
      end
    end

    # TODO
    field(:payer, :map)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
