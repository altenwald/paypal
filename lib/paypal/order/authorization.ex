defmodule Paypal.Order.Authorization do
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
      @seller_protection_statuses [
        eligible: "ELIGIBLE",
        partially_eligible: "PARTIALLY_ELIGIBLE",
        not_eligible: "NOT_ELIGIBLE"
      ]

      field(:status, Ecto.Enum, values: @seller_protection_statuses)
      # XXX looks like the categories are specific but the documentation is
      #     not listem them, so we are going to use `string` here.
      field(:dispute_categories, {:array, :string})
    end

    field(:expiration_time, :utc_datetime)
    field(:create_time, :utc_datetime)
    field(:update_time, :utc_datetime)
    embeds_many(:links, Link)
  end
end
