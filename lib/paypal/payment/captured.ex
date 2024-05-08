defmodule Paypal.Payment.Captured do
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
