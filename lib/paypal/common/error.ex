defmodule Paypal.Common.Error do
  use TypedEctoSchema
  alias Paypal.Common.Link

  @primary_key false

  typed_embedded_schema do
    field(:debug_id, :string, primary_key: true)

    embeds_many :details, Details, primary_key: false do
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
