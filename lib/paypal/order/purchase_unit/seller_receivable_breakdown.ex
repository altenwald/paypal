defmodule Paypal.Order.PurchaseUnit.SellerReceivableBreakdown do
  @moduledoc """
  The detailed breakdown of the capture activity, from a Capture.

  - `gross_amount` - the amount for this captured payment in the currency of the transaction.
  - `paypal_fee` - the fee that PayPal charges for the captured payment.
  - `net_amount` - the net amount the seller receives for this capture, in their receivable currency.
  - `paypal_fee_in_receivable_currency`, `receivable_amount`, `exchange_rate` - only present
    when currency conversion applies; kept as raw maps since their shape (and whether they
    appear at all) varies with the seller's receivable currency.
  """
  use TypedEctoSchema
  import Ecto.Changeset
  alias Paypal.Common.CurrencyValue

  @primary_key false
  typed_embedded_schema do
    embeds_one(:gross_amount, CurrencyValue)
    embeds_one(:paypal_fee, CurrencyValue)
    embeds_one(:net_amount, CurrencyValue)
    field(:paypal_fee_in_receivable_currency, :map)
    field(:receivable_amount, :map)
    field(:exchange_rate, :map)
  end

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, ~w[paypal_fee_in_receivable_currency receivable_amount exchange_rate]a)
    |> cast_embed(:gross_amount)
    |> cast_embed(:paypal_fee)
    |> cast_embed(:net_amount)
  end
end
