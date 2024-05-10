defmodule Paypal.Order.Authorized do
  @moduledoc """
  The authorized struct is the response performed by `Paypal.Order.authorize/1`
  where we can see the status of the authorization and other information
  related to the request.
  """
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Order
  alias Paypal.Order.Authorization

  @primary_key false

  @typedoc """
  The information related to the request is returning the order `id`, the final
  `status` for the order and the information for the authorization in the path
  `purchase_units/payments/authorizations`.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:status, Ecto.Enum, values: Order.statuses(), embed_as: :dumped)
    # TODO
    field(:payment_source, :map)

    embeds_many :purchase_units, PurchaseUnit, primary_key: false do
      @moduledoc false
      @typedoc false
      field(:reference_id, :string, primary_key: true)

      embeds_one :payments, Payment, primary_key: false do
        @moduledoc false
        @typedoc false
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
