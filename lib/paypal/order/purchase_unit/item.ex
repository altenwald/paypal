defmodule Paypal.Order.PurchaseUnit.Item do
  @moduledoc """
  The item inside of each purchase unit.
  See `Paypal.Order.PurchaseUnit`.
  """
  use TypedEctoSchema

  import Ecto.Changeset

  alias Paypal.Common.CurrencyValue
  alias Paypal.Order.UpcCode

  @derive Jason.Encoder

  @primary_key false

  @categories [
    digital_goods: "DIGITAL_GOODS",
    physical_goods: "PHYSICAL_GOODS",
    donation: "DONATION"
  ]

  @typedoc """
  The purchase unit has different items and each item has the following
  information:

  - `name` of the item.
  - `quantity` of the item included in the order.
  - `description` of the item.
  - `sku` is the ID for the item.
  - `url` is the URL for the item.
  - `category` is the category where the item is included.
  - `image_url` is the URL for the image.
  - `unit_amount` is the price for each unit.
  - `tax` is the price for the taxes.
  - `upc` is the UPC EAN code.
  """
  typed_embedded_schema do
    field(:name, :string)
    field(:quantity, :integer)
    field(:description, :string)
    field(:sku, :string)
    field(:url, :string)
    field(:category, Ecto.Enum, values: @categories)
    field(:image_url, :string)
    embeds_one(:unit_amount, CurrencyValue)
    embeds_one(:tax, CurrencyValue)
    embeds_one(:upc, UpcCode)
  end

  @required_fields ~w[name quantity]a
  @optional_fields ~w[description sku url category image_url]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_embed(:unit_amount, required: true)
    |> cast_embed(:tax)
    |> cast_embed(:upc)
    |> validate_required(@required_fields)
  end
end
