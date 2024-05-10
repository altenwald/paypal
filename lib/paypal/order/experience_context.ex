defmodule Paypal.Order.ExperienceContext do
  @moduledoc """
  The experience context is the information needed for creating an order
  and provide information about how Paypal should behave when we go to its
  website for performing the payment.
  """
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

  @typedoc """
  The customisation we could perform are the following ones:

  - `payment_method_experience` is unrestricted or immediate_payment_required.
  - `brand_name` is your branding that you want to show to your client.
  - `locale` is the language you want to use.
  - `landing_page` is where the user goes first:
    - `login` if we want the user see the paypal login page first.
    - `guest_checkout` if we want to Paypal show first the manual payment.
    - `no_preference` if we want Paypal choose based on the user.
  - `shipping_preference` is an indication about where we get the shipping
    data we could say here `no_shipping` for avoiding use a shipping address.
  - `user_action` is the action the user could do: continue or pay_now.
  - `return_url` is the URL where redirects when the payment is correct.
  - `cancel_url` is the URL where redirects when the payment is cancelled.
  """
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
