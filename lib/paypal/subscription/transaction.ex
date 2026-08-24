defmodule Paypal.Subscription.Transaction do
  @moduledoc """
  Transaction item within a subscription's transaction list.

  Official PayPal API Documentation:
  [List Transactions for Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_transactions)
  """
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue

  @statuses [
    completed: "COMPLETED",
    declined: "DECLINED",
    partially_refunded: "PARTIALLY_REFUNDED",
    pending: "PENDING",
    refunded: "REFUNDED",
    failed: "FAILED"
  ]

  @primary_key false

  @typedoc """
  Subscription transaction:

  - `id` - Transaction ID.
  - `status` - Transaction status (`:completed`, `:declined`, `:partially_refunded`, `:pending`, `:refunded`, `:failed`).
  - `amount_with_breakdown` - Monetary amount with breakdown.
  - `payer_name` - Map containing payer name (given_name, surname).
  - `payer_email` - Payer email address.
  - `time` - Date and time of the transaction.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:status, Ecto.Enum, values: @statuses)
    embeds_one(:amount_with_breakdown, CurrencyValue)
    field(:payer_name, :map)
    field(:payer_email, :string)
    field(:time, :utc_datetime)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
