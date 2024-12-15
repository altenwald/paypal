defmodule Paypal.Order.Payer do
  @moduledoc """
  Payer get all the information about who's paying the order.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  The information for the payer:

  - `payer_id` is the ID in Paypal for the payer.
  - `name` is a composition of two values: given_name and surname.
  - `email_address` is the email address provided to Paypal for the payment.
  """
  typed_embedded_schema do
    field(:payer_id, :string, primary_key: true)
    field(:name, :map)
    field(:email_address, :string)
  end
end
