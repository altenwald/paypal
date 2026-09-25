defmodule Paypal.Subscription.Product do
  @moduledoc """
  Manage catalog products for PayPal Subscriptions.

  Products represent the goods or services that you offer to your subscribers.
  Before creating a billing plan or subscription, you need to create a product.

  Official PayPal API Documentation:
  [PayPal Catalog Products API v1](https://developer.paypal.com/docs/api/catalog-products/v1/)
  """

  alias Paypal.Client
  alias Paypal.Common.Error, as: CommonError
  alias Paypal.Subscription.Product.Create
  alias Paypal.Subscription.Product.Info
  alias Paypal.Subscription.Product.List, as: ProductList

  defp client, do: Client.new("/v1/catalogs/products")

  defp get(uri, opts) do
    query =
      opts
      |> Keyword.get(:query, opts)
      |> Enum.into([])
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    Req.get(client(), url: uri, params: query)
  end

  defp post(uri, body) when is_map(body) or is_list(body),
    do: Req.post(client(), url: uri, json: body)

  defp post(uri, body),
    do: Req.post(client(), url: uri, body: body)

  defp patch(uri, body) when is_map(body) or is_list(body),
    do: Req.patch(client(), url: uri, json: body)

  defp patch(uri, body),
    do: Req.patch(client(), url: uri, body: body)

  @doc """
  Returns the supported product types:

  - `:physical` - Physical goods.
  - `:digital` - Digital goods.
  - `:service` - Services or recurring memberships.
  """
  @spec types() :: [physical: String.t(), digital: String.t(), service: String.t()]
  def types do
    [
      physical: "PHYSICAL",
      digital: "DIGITAL",
      service: "SERVICE"
    ]
  end

  @doc """
  Create a product.

  Official documentation:
  [Create Product](https://developer.paypal.com/docs/api/catalog-products/v1/#products_create)

  ## Examples

      iex> Paypal.Subscription.Product.create(%{
      ...>   name: "Video Streaming Service",
      ...>   type: :service,
      ...>   description: "Monthly video streaming access",
      ...>   category: "SOFTWARE"
      ...> })
      {:ok, %Paypal.Subscription.Product.Info{id: "PROD-123", ...}}

  """
  @spec create(map()) :: {:ok, Info.t()} | {:error, CommonError.t() | term()}
  def create(params) do
    with {:ok, data} <- Create.changeset(params),
         {:ok, %Req.Response{status: code, body: response}}
         when code in 200..299 and is_map(response) <-
           post("", data) do
      {:ok, Info.cast(response)}
    else
      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  List products with optional pagination filters.

  Official documentation:
  [List Products](https://developer.paypal.com/docs/api/catalog-products/v1/#products_list)

  ## Options

    - `:page_size` - Number of items per page (1 to 20, default 10).
    - `:page` - Page number (default 1).
    - `:total_required` - Whether total items count is returned (`true` or `false`).

  """
  @spec list(keyword() | map()) :: {:ok, ProductList.t()} | {:error, CommonError.t() | term()}
  def list(opts \\ []) do
    case get("", opts) do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, ProductList.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Show product details by product ID.

  Official documentation:
  [Show Product Details](https://developer.paypal.com/docs/api/catalog-products/v1/#products_get)
  """
  @spec show(String.t()) :: {:ok, Info.t()} | {:error, CommonError.t() | term()}
  def show(product_id) do
    case get("/#{product_id}", []) do
      {:ok, %Req.Response{status: 200, body: response}} when is_map(response) ->
        {:ok, Info.cast(response)}

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Update a product by ID using JSON Patch operations.

  Official documentation:
  [Update Product](https://developer.paypal.com/docs/api/catalog-products/v1/#products_patch)

  ## Examples

      iex> Paypal.Subscription.Product.update("PROD-123", [
      ...>   %{op: "replace", path: "/description", value: "New product description"}
      ...> ])
      :ok

  """
  @spec update(String.t(), [map()]) :: :ok | {:error, CommonError.t() | term()}
  def update(product_id, patch_operations) do
    case patch("/#{product_id}", patch_operations) do
      {:ok, %Req.Response{status: code}} when code in 200..299 ->
        :ok

      {:ok, %Req.Response{body: response}} ->
        {:error, CommonError.cast(response)}

      {:error, _} = error ->
        error
    end
  end
end
