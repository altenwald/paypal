defmodule Paypal.Common.Link do
  @moduledoc """
  The link is accumulating all of the required information for handling the
  HATEOAS links.
  """
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

  @typedoc """
  The possible values for the links are:

  - `enc_type` is the kind of encoding the request is providing or requiring.
    It's not compulsory for most of the links.
  - `href` is the URL for the link.
  - `rel` is the name for the link. The name is based on the RFC-8288.
  - `method` is the HTTP method that is needed for the request.
  """
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
