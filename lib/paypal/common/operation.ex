defmodule Paypal.Common.Operation do
  use TypedEctoSchema

  alias Paypal.Common.Link

  @statuses [
    created: "CREATED",
    saved: "SAVED",
    approved: "APPROVED",
    voided: "VOIDED",
    completed: "COMPLETED",
    payer_action_required: "PAYER_ACTION_REQUIRED"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    embeds_many(:links, Link)
    field(:status, Ecto.Enum, values: @statuses)
  end

  @doc false
  def cast(data) do
    Ecto.embedded_load(__MODULE__, data, :json)
  end
end
