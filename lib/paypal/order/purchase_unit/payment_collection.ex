defmodule Paypal.Order.PurchaseUnit.PaymentCollection do
  @moduledoc """
  Represents a Payment Collection object from the PayPal v2 API.

  This object holds details about payment captures, refunds, and authorizations.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Paypal.Order.Authorization
  alias Paypal.Order.PurchaseUnit.Capture

  typed_embedded_schema do
    embeds_many(:captures, Capture)
    embeds_many(:authorizations, Authorization)
    # TODO
    field(:refunds, :map)
  end

  @fields ~w[
    refunds
  ]a

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @fields)
    |> cast_embed(:captures, with: &Capture.changeset/2)
    |> cast_embed(:authorizations, with: &Authorization.changeset/2)
  end
end
