defmodule Paypal.Common.Error do
  @moduledoc """
  When something goes wrong, Paypal is replying us with an error message
  and this is the struct for retrieving this kind of errors.
  """
  use TypedEctoSchema
  alias Paypal.Common.Link

  @primary_key false

  @typedoc """
  The information given by Paypal for each error is as follows:

  - `debug_id` is the ID for debugging the error.
  - `details` is a list of details about the errors.
  - `links` is the list of links (HATEOAS).
  - `message` is the error message to try to understand why it failed.
  - `name` is the error name.
  """
  typed_embedded_schema do
    field(:debug_id, :string, primary_key: true)

    embeds_many :details, Details, primary_key: false do
      @moduledoc false
      @typedoc false

      field(:field, :string)
      field(:description, :string)
      field(:issue, :string)
      field(:location, :string)
      field(:value, :string)
    end

    embeds_many(:links, Link)
    field(:message, :string)
    field(:name, :string)
  end

  @doc false
  def cast(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end
end
