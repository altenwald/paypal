defmodule Paypal.Common.Operation do
  @moduledoc """
  The operation is the struct where we store the information for the operations
  performed in orders and payments. Most of the requests that are performing an
  action is returning an operation.
  """
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

  @typedoc """
  The information provided is an `id` for the operation (order or payment),
  the `links` for performing other actions based on the return and the
  `status` of the operation.
  """
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
