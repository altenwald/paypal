defmodule Paypal.Common.Link do
  use TypedEctoSchema

  @primary_key false

  @methods [
    get: "GET",
    post: "POST",
    put: "PUT",
    delete: "DELETE",
    head: "HEAD",
    connect: "CONNECT",
    options: "OPTIONS",
    patch: "PATCH"
  ]

  typed_embedded_schema do
    field(:enc_type, :string, source: :encType)
    field(:href, :string)
    field(:rel, :string)
    field(:method, Ecto.Enum, values: @methods, embeds_as: :dumped)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
