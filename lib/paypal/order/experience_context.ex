defmodule Paypal.Order.ExperienceContext do
  use TypedEctoSchema
  import Ecto.Changeset
  import Paypal.EctoHelpers

  @primary_key false

  @methods [
    unrestricted: "UNRESTRICTED",
    immediate_payment_required: "IMMEDIATE_PAYMENT_REQUIRED"
  ]

  @landings [
    login: "LOGIN",
    guest_checkout: "GUEST_CHECKOUT",
    no_preference: "NO_PREFERENCE"
  ]

  @shipping [
    get_from_file: "GET_FROM_FILE",
    no_shipping: "NO_SHIPPING",
    set_provided_address: "SET_PROVIDED_ADDRESS"
  ]

  @user_actions [
    continue: "CONTINUE",
    pay_now: "PAY_NOW"
  ]

  typed_embedded_schema do
    field(:payment_method_experience, Ecto.Enum, values: @methods, embed_as: :dumped)
    field(:brand_name, :string)
    field(:locale, :string, default: "en-US")

    field(:landing_page, Ecto.Enum,
      values: @landings,
      default: :no_preference,
      embed_as: :dumped
    )

    field(:shipping_preference, Ecto.Enum,
      values: @shipping,
      default: :no_shipping,
      embed_as: :dumped
    )

    field(:user_action, Ecto.Enum, values: @user_actions, default: :pay_now, embed_as: :dumped)
    field(:return_url, :string)
    field(:cancel_url, :string)
  end

  @required_fields ~w[return_url cancel_url]a
  @optional_fields ~w[payment_method_experience brand_name locale landing_page shipping_preference user_action]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        {:ok,
         changeset
         |> apply_changes()
         |> Ecto.embedded_dump(:json)}

      %Ecto.Changeset{} = changeset ->
        {:error, traverse_errors(changeset)}
    end
  end
end
