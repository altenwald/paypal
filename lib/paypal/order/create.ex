defmodule Paypal.Order.Create do
  @moduledoc """
  Create an order. It contains the information for creating an order.
  """
  use TypedEctoSchema

  import Ecto.Changeset
  import Paypal.EctoHelpers

  alias Paypal.Order
  alias Paypal.Order.PurchaseUnit

  @derive Jason.Encoder

  @primary_key false

  @typedoc """
  The information for creating an order is based on two principal data:

  - `intent` that could be `:capture` or `:authorize`.
  - `purchase_units` that is the information for the payment.
    See `Paypal.Order.PurchaseUnit`.
  """
  typed_embedded_schema do
    field(:intent, Ecto.Enum, values: Order.intents(), embed_as: :dumped)
    embeds_many(:purchase_units, PurchaseUnit)
  end

  @doc false
  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, [:intent])
    |> cast_embed(:purchase_units, required: true)
    |> validate_required([:intent])
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

  defp clean_data(map) when is_map(map) and not is_struct(map) do
    map
    |> Map.reject(fn {_key, value} -> value in [nil, []] end)
    |> Map.new(fn {key, value} -> {key, clean_data(value)} end)
  end

  defp clean_data(list) when is_list(list) do
    list
    |> Enum.reject(&(&1 in [nil, []]))
    |> Enum.map(&clean_data/1)
  end

  defp clean_data(otherwise), do: otherwise
end
