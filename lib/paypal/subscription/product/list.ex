defmodule Paypal.Subscription.Product.List do
  @moduledoc """
  Product list response returned from the PayPal Catalog Products API.

  For more details, see the [PayPal Catalog Products API documentation](https://developer.paypal.com/docs/api/catalog-products/v1/#products_list).
  """
  use TypedEctoSchema

  alias Paypal.Common.Link
  alias Paypal.Subscription.Product.Info

  @primary_key false

  @typedoc """
  Product list structure:

  - `products` - List of product items.
  - `total_items` - Total count of items available across pages.
  - `total_pages` - Total number of pages available.
  - `links` - HATEOAS pagination links.
  """
  typed_embedded_schema do
    embeds_many(:products, Info)
    field(:total_items, :integer)
    field(:total_pages, :integer)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
