defmodule Paypal.Subscription.Plan.BillingCycle do
  @moduledoc """
  Represents a billing cycle inside a PayPal billing plan.

  Official PayPal API Documentation:
  [Billing Cycles](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_create)
  """
  use TypedEctoSchema

  import Ecto.Changeset

  @derive Jason.Encoder

  @tenure_types [
    regular: "REGULAR",
    trial: "TRIAL"
  ]

  @primary_key false

  @typedoc """
  Billing cycle definition:

  - `tenure_type` - Cycle type: `:regular` or `:trial`.
  - `sequence` - The order of the cycle (1, 2, etc.).
  - `total_cycles` - Number of times cycle repeats (`0` for infinite).
  - `frequency` - Map with `interval_unit` ("DAY", "WEEK", "MONTH", "YEAR") and `interval_count`.
  - `pricing_scheme` - Map with `fixed_price` (containing `currency_code` and `value`).
  """
  typed_embedded_schema do
    field(:tenure_type, Ecto.Enum, values: @tenure_types, embed_as: :dumped)
    field(:sequence, :integer)
    field(:total_cycles, :integer, default: 1)
    field(:frequency, :map)
    field(:pricing_scheme, :map)
  end

  @fields ~w[tenure_type sequence total_cycles frequency pricing_scheme]a
  @required_fields ~w[tenure_type sequence frequency]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end
