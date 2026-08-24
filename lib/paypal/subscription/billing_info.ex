defmodule Paypal.Subscription.BillingInfo do
  @moduledoc """
  Billing details and cycle execution information for a PayPal subscription.

  Official PayPal API Documentation:
  [Subscription Billing Info](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_get)
  """
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue

  @primary_key false

  @typedoc """
  Subscription billing info:

  - `outstanding_balance` - Monetary amount currently owed.
  - `cycle_executions` - List of executed billing cycle details.
  - `last_payment` - Last payment info including amount and date.
  - `next_billing_time` - Date and time for next scheduled payment.
  - `final_payment_time` - Date and time for final payment if applicable.
  - `failed_payments_count` - Number of consecutive failed payment attempts.
  """
  typed_embedded_schema do
    embeds_one(:outstanding_balance, CurrencyValue)
    field(:cycle_executions, {:array, :map})
    field(:last_payment, :map)
    field(:next_billing_time, :utc_datetime)
    field(:final_payment_time, :utc_datetime)
    field(:failed_payments_count, :integer, default: 0)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
