defmodule Paypal.Order.UpcCode do
  @moduledoc """
  The UPC EAN code.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  @derive Jason.Encoder

  @primary_key false

  @upc_types [
    upc_a: "UPC-A",
    upc_b: "UPC-B",
    upc_c: "UPC-C",
    upc_d: "UPC-D",
    upc_e: "UPC-E",
    upc_2: "UPC-2",
    upc_5: "UPC-5"
  ]

  @typedoc """
  It's defining the `type` for the UPC code (i.e. UPC-A) and the `code`.
  """
  typed_embedded_schema do
    field(:type, Ecto.Enum, values: @upc_types)
    field(:code, :string)
  end

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, ~w[type code]a)
    |> validate_required(~w[type code]a)
    |> validate_length(:code, min: 6, max: 17)
  end
end
