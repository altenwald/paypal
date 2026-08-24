defmodule Paypal.Subscription.Plan.PaymentPreferences do
  @moduledoc """
  Payment preferences for a PayPal billing plan.

  Official PayPal API Documentation:
  [Payment Preferences](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_create)
  """
  use TypedEctoSchema

  import Ecto.Changeset

  alias Paypal.Common.CurrencyValue

  @derive Jason.Encoder

  @setup_fee_actions [
    continue: "CONTINUE",
    cancel: "CANCEL"
  ]

  @primary_key false

  @typedoc """
  Payment preferences:

  - `auto_bill_outstanding` - Whether to automatically bill outstanding amount in next cycle.
  - `setup_fee` - Initial setup fee amount.
  - `setup_fee_failure_action` - Action if setup fee fails (`:continue` or `:cancel`).
  - `payment_failure_threshold` - Number of failed payments before subscription is suspended.
  """
  typed_embedded_schema do
    field(:auto_bill_outstanding, :boolean, default: true)
    embeds_one(:setup_fee, CurrencyValue)

    field(:setup_fee_failure_action, Ecto.Enum,
      values: @setup_fee_actions,
      default: :cancel,
      embed_as: :dumped
    )

    field(:payment_failure_threshold, :integer, default: 0)
  end

  @fields ~w[auto_bill_outstanding setup_fee_failure_action payment_failure_threshold]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:setup_fee)
  end
end
