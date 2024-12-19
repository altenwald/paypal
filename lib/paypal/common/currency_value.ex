defmodule Paypal.Common.CurrencyValue do
  @moduledoc """
  Most of the currencies in the Paypal requests and responses are handled
  as a JSON object that is including `currency_code` and `value`. But it's
  even more complex in other requests.

  This struct contains the possibilities for all of these requests/responses.
  """
  use TypedEctoSchema
  import Ecto.Changeset

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  The type is composed by the following:

  - `currency_code` is the currency code based on ISO-4217, i.e. EUR
  - `value` is the decimal or integer value for the currency.
  - `breakdown` is expressing information for the money.

  About the breakdown, we could find that if it's provided, it could include
  information like this one:

  ```elixir
  %{
    "item_total" => %{
      "currency_code" => "EUR",
      "value" => "12.00"
    },
    "shipping" => %{
      "currency_code" => "EUR",
      "value" => "2.00"
    },
    "discount" => {
      "currency_code" => "EUR",
      "value" => "5.00"
    }
  }
  ```
  """
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
