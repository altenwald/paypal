defmodule Paypal.Payment.Info do
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link

  @statuses [
    created: "CREATED",
    captured: "CAPTURED",
    denied: "DENIED",
    partially_captured: "PARTIALLY_CAPTURED",
    voided: "VOIDED",
    pending: "PENDING",
    completed: "COMPLETED"
  ]

  @primary_key false

  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:create_time, :utc_datetime)
    field(:expiration_time, :utc_datetime)
    embeds_one(:amount, CurrencyValue)
    embeds_many(:links, Link)
    # TODO
    field(:payee, :map)
    field(:status, Ecto.Enum, values: @statuses)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
