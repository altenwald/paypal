defmodule Paypal.Order.PurchaseUnit.Item do
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
