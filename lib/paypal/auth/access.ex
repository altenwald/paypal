defmodule Paypal.Auth.Access do
  @moduledoc """
  The access structure has the information for accessing to the rest of
  the requests and the information about the expiration of the token.
  """
  use TypedEctoSchema
  import Ecto.Changeset
  import Paypal.EctoHelpers

  @primary_key false

  @typedoc """
  The information stored inside of the access structure is the following:

  - `scope` is a list of URLs we can access or use with the access token.
  - `access_token` is the hash we need for the other requests.
  - `token_type` is the type of the token generated. Usually it's `Bearer`.
  - `app_id` is the ID of the application.
  - `expires_in` is the number of seconds for expiring the token.
  - `nonce` is the nonce used.
  """
  typed_embedded_schema do
    field(:scope, :string)
    field(:access_token, :string)
    field(:token_type, :string)
    field(:app_id, :string)
    field(:expires_in, :integer)
    field(:nonce, :string)
  end

  @fields ~w[scope access_token token_type app_id expires_in nonce]a

  @doc """
  Perform the transformation of the input data from the Paypal server to the
  access struct.
  """
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
