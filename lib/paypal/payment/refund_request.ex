defmodule Paypal.Payment.RefundRequest do
  @moduledoc """
  Request object that Refunds a captured payment, by ID. For a full refund, include an empty
  request body. For a partial refund, include an `amount` object in
  the request body.

  ## Fields

    - `amount` - The currency and amount for a financial transaction, such as a balance or payment due.
    - `custom_id` - The API caller-provided external ID. Used to reconcile API caller-initiated transactions with PayPal transactions.
    - `invoice_id` - The API caller-provided external invoice ID for this order.
    - `note_to_payer` - The reason for the refund. Appears in both the payer's transaction history and the emails that the payer receives.
    - `payment_instruction` - Any additional payments instructions during refund payment processing.
  """

  use TypedEctoSchema
  import Ecto.Changeset
  alias Paypal.Common.CurrencyValue

  @derive Jason.Encoder
  @primary_key false
  typed_embedded_schema do
    embeds_one(:amount, CurrencyValue)
    field(:custom_id, :string)
    field(:invoice_id, :string)
    field(:note_to_payer, :string)
    # TODO
    field(:payment_instruction, :map)
  end

  @fields ~w[
    custom_id
    invoice_id
    note_to_payer
    payment_instruction
  ]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:amount)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
