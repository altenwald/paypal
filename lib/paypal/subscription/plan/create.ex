defmodule Paypal.Subscription.Plan.Create do
  @moduledoc """
  Schema and validation for creating a billing plan in PayPal.

  Official PayPal API Documentation:
  [Create Plan](https://developer.paypal.com/docs/api/subscriptions/v1/#plans_create)
  """
  use TypedEctoSchema

  import Ecto.Changeset
  import Paypal.EctoHelpers

  alias Paypal.Subscription.Plan
  alias Paypal.Subscription.Plan.BillingCycle
  alias Paypal.Subscription.Plan.PaymentPreferences
  alias Paypal.Subscription.Plan.Taxes

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  Fields for creating a billing plan:

  - `product_id` - The product ID (required).
  - `name` - The plan name (required).
  - `description` - Plan description.
  - `status` - Status (`:active` or `:inactive`, default `:active`).
  - `billing_cycles` - List of billing cycle maps/structs (required).
  - `payment_preferences` - Payment preferences map/struct (required).
  - `taxes` - Taxes map/struct.
  - `quantity_supported` - Whether quantity is supported.
  """
  typed_embedded_schema do
    field(:product_id, :string)
    field(:name, :string)
    field(:description, :string)
    field(:status, Ecto.Enum, values: Plan.statuses(), default: :active, embed_as: :dumped)
    embeds_many(:billing_cycles, BillingCycle)
    embeds_one(:payment_preferences, PaymentPreferences)
    embeds_one(:taxes, Taxes)
    field(:quantity_supported, :boolean, default: false)
  end

  @fields ~w[product_id name description status quantity_supported]a
  @required_fields ~w[product_id name]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:billing_cycles, required: true)
    |> cast_embed(:payment_preferences)
    |> cast_embed(:taxes)
    |> validate_required(@required_fields)
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
