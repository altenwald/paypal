defmodule Paypal.Order.PurchaseUnit do
  @moduledoc """
  The purchase unit is the information for each unit purchased (or to purchase)
  included in an order.
  """
  use TypedEctoSchema

  import Ecto.Changeset

  alias Paypal.Common.CurrencyValue
  alias Paypal.Order.PurchaseUnit.Item
  alias Paypal.Order.PurchaseUnit.PaymentCollection

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  The information for the purchase unit. It's composed for the provided
  items to be purchased, the information about the payee, payment instructions,
  shipping, etc.
  """
  typed_embedded_schema do
    field(:reference_id, :string, default: "default")
    field(:description, :string)
    field(:custom_id, :string)
    field(:invoice_id, :string)
    field(:soft_descriptor, :string)
    embeds_many(:items, Item)
    embeds_one(:amount, CurrencyValue)
    embeds_one(:payments, PaymentCollection)
    # TODO
    field(:payee, :map)
    # TODO
    field(:payment_instruction, :map)
    # TODO
    field(:shipping, :map)
    # TODO
    field(:supplementary_data, :map)
  end

  @fields ~w[
    reference_id
    description
    custom_id
    invoice_id
    soft_descriptor
    payee
    payment_instruction
    shipping
    supplementary_data
  ]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:amount, required: true)
    |> cast_embed(:items)
    |> cast_embed(:payments)
    |> validate_length(:reference_id, min: 1, max: 256)
    |> validate_length(:description, min: 1, max: 127)
    |> validate_length(:custom_id, min: 1, max: 127)
    |> validate_length(:invoice_id, min: 1, max: 127)
    |> validate_length(:soft_descriptor, min: 1, max: 22)
  end
end
