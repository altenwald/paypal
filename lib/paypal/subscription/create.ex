defmodule Paypal.Subscription.Create do
  @moduledoc """
  Schema and validation for creating a subscription in PayPal.

  Official PayPal API Documentation:
  [Create Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_create)
  """
  use TypedEctoSchema

  import Ecto.Changeset
  import Paypal.EctoHelpers

  alias Paypal.Common.CurrencyValue
  alias Paypal.Subscription.Subscriber

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  Fields for creating a subscription:

  - `plan_id` - The billing plan ID (required).
  - `start_time` - Start time for the subscription (ISO 8601 string or datetime).
  - `quantity` - Subscription quantity.
  - `shipping_amount` - Shipping amount struct or map.
  - `subscriber` - Subscriber struct or map.
  - `application_context` - Map containing return_url, cancel_url, brand_name, locale, etc.
  - `custom_id` - Custom ID for tracking.
  - `plan` - Custom plan override if applicable.
  """
  typed_embedded_schema do
    field(:plan_id, :string)
    field(:start_time, :string)
    field(:quantity, :string)
    embeds_one(:shipping_amount, CurrencyValue)
    embeds_one(:subscriber, Subscriber)
    field(:application_context, :map)
    field(:custom_id, :string)
    field(:plan, :map)
  end

  @fields ~w[plan_id start_time quantity application_context custom_id plan]a
  @required_fields ~w[plan_id]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:shipping_amount)
    |> cast_embed(:subscriber)
    |> validate_required(@required_fields)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok,
         changeset
         |> apply_changes()
         |> Ecto.embedded_dump(:json)
         |> clean_data()}

      %Ecto.Changeset{} = changeset ->
        {:error, traverse_errors(changeset)}
    end
  end
end
