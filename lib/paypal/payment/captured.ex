defmodule Paypal.Payment.Captured do
  @moduledoc """
  The returned information after performing a capture of an authorized order.
  """
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link

  @statuses [
    completed: "COMPLETED",
    declined: "DECLINED",
    partially_refunded: "PARTIALLY_REFUNDED",
    pending: "PENDING",
    refunded: "REFUNDED",
    failed: "FAILED"
  ]

  @disbursement_modes [
    instant: "INSTANT",
    delayed: "DELAYED"
  ]

  @primary_key false

  @typedoc """
  The information about the captured order is the following one:

  - `id` for the authorized order.
  - `invoice_id` (optional) is the provided invoice ID provided when the order
    was created or authorized.
  - `custom_id` (optional) is the provided custom ID when the order was created
    or authorized.
  - `final_capture` it's about a fraction of the order to be paid.
  - `links` are the links about the following possible options (HATEOAS).
  - `status` for the authorized order.
  - `status_details` is a string defining the status for the authorized order.
  - `disbursement_mode`
  - `amount` is the price for the order to be paid.
  - `create_time` (optional) is the time when the authorized order was created.
  - `update_time` (optional) is the time when the authorized order was updated.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:invoice_id, :string)
    field(:custom_id, :string)
    field(:final_capture, :boolean, default: false)
    embeds_many(:links, Link)
    field(:status, Ecto.Enum, values: @statuses, embed_as: :dumped)

    # TODO https://developer.paypal.com/docs/api/payments/v2/#authorizations_capture!c=201&path=status_details/reason&t=response
    field(:status_details, :map)

    field(:disbursement_mode, Ecto.Enum,
      values: @disbursement_modes,
      default: :instant,
      embed_as: :dumped
    )

    embeds_one(:amount, CurrencyValue)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
