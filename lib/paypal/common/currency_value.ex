defmodule Paypal.Common.CurrencyValue do
  use TypedEctoSchema
  import Ecto.Changeset

  @derive Jason.Encoder

  @primary_key false

  typed_embedded_schema do
    field(:currency_code, :string)
    field(:value, :decimal)
    field(:breakdown, :map)
  end

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, ~w[currency_code value breakdown]a)
    |> validate_required(~w[currency_code value]a)
    |> validate_length(:currency_code, is: 3)
  end
end
