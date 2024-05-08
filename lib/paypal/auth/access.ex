defmodule Paypal.Auth.Access do
  use TypedEctoSchema
  import Ecto.Changeset
  import Paypal.EctoHelpers

  @primary_key false

  typed_embedded_schema do
    field(:scope, :string)
    field(:access_token, :string)
    field(:token_type, :string)
    field(:app_id, :string)
    field(:expires_in, :integer)
    field(:nonce, :string)
  end

  @fields ~w[scope access_token token_type app_id expires_in nonce]a

  def cast(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok, apply_changes(changeset)}

      %Ecto.Changeset{} = changeset ->
        {:error, traverse_errors(changeset)}
    end
  end
end
