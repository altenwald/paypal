defmodule Paypal.Subscription.Subscriber do
  @moduledoc """
  Subscriber details in a PayPal subscription.

  Official PayPal API Documentation:
  [Subscriber Details](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_get)
  """
  use TypedEctoSchema

  import Ecto.Changeset

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  Subscriber details:

  - `email_address` - The email address of the subscriber.
  - `payer_id` - The PayPal account ID of the subscriber.
  - `name` - Map containing subscriber given_name and surname.
  - `shipping_address` - Map containing subscriber shipping address.
  """
  typed_embedded_schema do
    field(:email_address, :string)
    field(:payer_id, :string)
    field(:name, :map)
    field(:shipping_address, :map)
  end

  @fields ~w[email_address payer_id name shipping_address]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    cast(model, params, @fields)
  end
end
