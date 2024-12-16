defmodule Paypal.Order.Authorization do
  @moduledoc """
  Authorization is the information embebed into the
  `Paypal.Order.Authorized` for getting all of the information for the
  authorized payment.
  """
  use TypedEctoSchema

  alias Paypal.Common.CurrencyValue
  alias Paypal.Common.Link

  @statuses [
    created: "CREATED",
    captured: "CAPTURED",
    denied: "DENIED",
    partially_captured: "PARTIALLY_CAPTURED",
    voided: "VOIDED",
    pending: "PENDING",
    completed: "COMPLETED"
  ]

  @primary_key false

  @typedoc """
  The information about the authorization performed on an order.
  The important information here is the `id` because it will be
  important to perform actions using `Paypal.Payment` functions.
  """
  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:status, Ecto.Enum, values: @statuses, embed_as: :dumped)
    # XXX this is not very useful so, at the moment we are going to keep it
    #     as a simple map:
    field(:status_details, :map)
    field(:invoice_id, :string)
    field(:custom_id, :string)
    embeds_one(:amount, CurrencyValue)
    # TODO
    field(:network_transaction_reference, :map)

    embeds_one :seller_protection, SellerProtection, primary_key: false do
      @moduledoc """
      Seller protection gives us information about if the protection of the
      seller is elegible and the categories for the disputes.
      """

      @seller_protection_statuses [
        eligible: "ELIGIBLE",
        partially_eligible: "PARTIALLY_ELIGIBLE",
        not_eligible: "NOT_ELIGIBLE"
      ]

      @typedoc """
      Seller protection gives us the eligibility of the seller and the kind
      of disputes.
      """

      field(:status, Ecto.Enum, values: @seller_protection_statuses)
      # XXX looks like the categories are specific but the documentation is
      #     not listen them, so we are going to use `string` here.
      field(:dispute_categories, {:array, :string})
    end

    field(:expiration_time, :utc_datetime)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
  end
end
