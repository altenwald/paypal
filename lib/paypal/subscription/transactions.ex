defmodule Paypal.Subscription.Transactions do
  @moduledoc """
  Transactions response returned for a PayPal subscription.

  Official PayPal API Documentation:
  [List Transactions for Subscription](https://developer.paypal.com/docs/api/subscriptions/v1/#subscriptions_transactions)
  """
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Subscription.Transaction

  @primary_key false

  @typedoc """
  Subscription transactions structure:

  - `transactions` - List of subscription transactions.
  - `total_items` - Total count of items available across pages.
  - `total_pages` - Total number of pages available.
  - `links` - HATEOAS pagination links.
  """
  typed_embedded_schema do
    embeds_many(:transactions, Transaction)
    field(:total_items, :integer)
    field(:total_pages, :integer)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
