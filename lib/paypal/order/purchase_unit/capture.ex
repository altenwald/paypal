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
    - `disbursement_mode` - An embedded schema containing details about the disbursement mode.
    - `processor_response` - An embedded schema containing details about the processor response.
    - `seller_protection` - An embedded schema containing details about seller protection.
    - `seller_receivable_breakdown` - An embedded schema that details the receivables.
    - `network_transaction_reference` - Reference values used by the card network to identify a transaction.
    - `links` - A list of embedded link objects for further API actions.
  """

  use TypedEctoSchema
  import Ecto.Changeset
  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link

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
    # TODO
    field(:seller_protection, :map)
    # TODO
    field(:seller_receivable_breakdown, :map)
    # TODO
    field(:network_transaction_reference, :map)
    # TODO
    field(:disbursement_mode, :map)
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
    seller_protection
    final_capture
    seller_receivable_breakdown
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
  end
end
