defmodule Paypal.Subscription.Product.Create do
  @moduledoc """
  Schema and validation for creating a product in the PayPal Catalog Products API.

  For more details, see the [PayPal Catalog Products API documentation](https://developer.paypal.com/docs/api/catalog-products/v1/#products_create).
  """
  use TypedEctoSchema

  import Ecto.Changeset
  import Paypal.EctoHelpers

  alias Paypal.Subscription.Product

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  Fields for creating a product:

  - `name` - The product name (required, max 127 characters).
  - `type` - The product type: `:physical`, `:digital`, or `:service` (required).
  - `id` - Optional custom product ID (max 127 characters).
  - `description` - Optional product description (max 256 characters).
  - `category` - Optional product category (max 256 characters).
  - `image_url` - Optional product image URL.
  - `home_url` - Optional product home page URL.
  """
  typed_embedded_schema do
    field(:id, :string)
    field(:name, :string)
    field(:description, :string)
    field(:type, Ecto.Enum, values: Product.types(), embed_as: :dumped)
    field(:category, :string)
    field(:image_url, :string)
    field(:home_url, :string)
  end

  @fields ~w[id name description type category image_url home_url]a
  @required_fields ~w[name type]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 1, max: 127)
    |> validate_length(:description, max: 256)
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
