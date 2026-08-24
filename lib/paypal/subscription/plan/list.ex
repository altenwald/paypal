defmodule Paypal.Subscription.Plan.List do
  @moduledoc """
  Plan list response returned from the PayPal Billing Plans API.

  Official PayPal API Documentation:
  [List Plans](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_list)
  """
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Subscription.Plan.Info

  @primary_key false

  @typedoc """
  Plan list structure:

  - `plans` - List of plan items.
  - `total_items` - Total count of items available across pages.
  - `total_pages` - Total number of pages available.
  - `links` - HATEOAS pagination links.
  """
  typed_embedded_schema do
    embeds_many(:plans, Info)
    field(:total_items, :integer)
    field(:total_pages, :integer)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
