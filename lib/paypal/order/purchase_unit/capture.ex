defmodule Paypal.Order.PurchaseUnit.Capture do
  @moduledoc """
  Represents a Capture object from the PayPal v2 PurchaseUnit API.

  ## Fields

    - `id` - The unique ID for the capture.
    - `status` - The status of the capture (e.g. `"COMPLETED"`).
    - `status_details` - The details of the capture status.
    - `invoice_id` - The API caller-provided external invoice number for this order.
    - `custom_id` - The API caller-provided external ID.
    - `final_capture` - A boolean indicating if this is the final capture.
    - `create_time` - The date and time when the capture was created (ISO 8601 string).
    - `update_time` - The date and time when the capture was last updated (ISO 8601 string).
    - `amount` - An embedded schema representing the monetary amount of the capture.
    - `disbursement_mode` - Either `:instant` or `:delayed`.
    - `processor_response` - An embedded schema containing details about the processor response.
    - `seller_protection` - Whether the capture is covered by seller protection, see `Paypal.Order.PurchaseUnit.SellerProtection`.
    - `seller_receivable_breakdown` - The fee/net breakdown for the capture, see `Paypal.Order.PurchaseUnit.SellerReceivableBreakdown`.
    - `network_transaction_reference` - Reference values used by the card network to identify a transaction.
    - `links` - A list of embedded link objects for further API actions.
  """

  use TypedEctoSchema
  import Ecto.Changeset
  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link
  alias Paypal.Order.PurchaseUnit.SellerProtection
  alias Paypal.Order.PurchaseUnit.SellerReceivableBreakdown

  @disbursement_modes [
    instant: "INSTANT",
    delayed: "DELAYED"
  ]

  @primary_key false
  typed_embedded_schema do
    field(:id, :string)
    field(:status, :string)
    field(:status_details, :string)
    field(:invoice_id, :string)
    field(:custom_id, :string)
    field(:final_capture, :boolean)
    field(:create_time, :string)
    field(:update_time, :string)
    embeds_one(:seller_protection, SellerProtection)
    embeds_one(:seller_receivable_breakdown, SellerReceivableBreakdown)
    # TODO
    field(:network_transaction_reference, :map)
    field(:disbursement_mode, Ecto.Enum, values: @disbursement_modes, embed_as: :dumped)
    # TODO
    field(:processor_response, :map)

    embeds_one(:amount, CurrencyValue)
    embeds_many(:links, Link)
  end

  @fields ~w[
    status
    status_details
    id
    invoice_id
    custom_id
    network_transaction_reference
    final_capture
    disbursement_mode
    processor_response
    create_time
    update_time
  ]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:amount, required: true)
    |> cast_embed(:links)
    |> cast_embed(:seller_protection)
    |> cast_embed(:seller_receivable_breakdown)
  end
end
