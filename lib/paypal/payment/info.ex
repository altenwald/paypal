defmodule Paypal.Payment.Info do
  @moduledoc """
  Authorized order information.
  """
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

  @typedoc """
  The retrieved authorized order information is the following one:

  - `id` for the authorized order ID.
  - `create_time` is the date and time when the order was created.
  - `expiration_time` is the date and time when the authorization expries.
  - `amount` is the price to be paid.
  - `links` are the possible actions to follow (HATEOAS).
  - `payee` is the information about who is paying the order.
  - `status` is the status for the authorized order.
  """
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
