defmodule Paypal.Subscription.Product.Info do
  @moduledoc """
  Product information retrieved from the PayPal Catalog Products API.

  For more details, see the [PayPal Catalog Products API documentation](https://developer.paypal.com/docs/api/catalog-products/v1/).
  """
  use TypedEctoSchema

  alias Paypal.Common.Link

  @types [
    physical: "PHYSICAL",
    digital: "DIGITAL",
    service: "SERVICE"
  ]

  @primary_key false

  @typedoc """
  Product details:

  - `id` - The unique product ID.
  - `name` - The product name.
  - `description` - The product description.
  - `type` - The product type (`:physical`, `:digital`, or `:service`).
  - `category` - The product category.
  - `image_url` - The image URL for the product.
  - `home_url` - The home URL for the product.
  - `create_time` - The date and time when the product was created.
  - `update_time` - The date and time when the product was last updated.
  - `links` - HATEOAS links related to the product.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:name, :string)
    field(:description, :string)
    field(:type, Ecto.Enum, values: @types)
    field(:category, :string)
    field(:image_url, :string)
    field(:home_url, :string)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
