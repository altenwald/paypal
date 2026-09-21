defmodule Paypal.Order.PurchaseUnit.SellerProtection do
  @moduledoc """
  Indicates whether the transaction is eligible for seller protection, from a Capture.

  - `status` - `"ELIGIBLE"`, `"PARTIALLY_ELIGIBLE"` or `"NOT_ELIGIBLE"`.
  - `dispute_categories` - the categories covered when eligible, e.g. `"ITEM_NOT_RECEIVED"`.

  Kept as plain strings (not an `Ecto.Enum`) so an unlisted value from PayPal
  never crashes decoding -- see the `disbursement_mode` fix this mirrors.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  typed_embedded_schema do
    field(:status, :string)
    field(:dispute_categories, {:array, :string}, default: [])
  end

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    cast(model, params, ~w[status dispute_categories]a)
  end
end
