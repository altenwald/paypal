defmodule Paypal.Subscription.Plan.Taxes do
  @moduledoc """
  Tax details for a PayPal billing plan.

  Official PayPal API Documentation:
  [Plan Taxes](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_create)
  """
  use TypedEctoSchema

  import Ecto.Changeset

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  Taxes:

  - `percentage` - Tax percentage (e.g., "10" or "21.00").
  - `inclusive` - Whether the tax is inclusive in the product price.
  """
  typed_embedded_schema do
    field(:percentage, :string)
    field(:inclusive, :boolean, default: false)
  end

  @fields ~w[percentage inclusive]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> validate_required(~w[percentage]a)
  end
end
