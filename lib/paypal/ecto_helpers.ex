defmodule Paypal.EctoHelpers do
  @moduledoc """
  Ecto Helpers is a module that is ensuring we have the common functions in
  use for most of the schemas or modules that uses Ecto.
  """
  import Ecto.Changeset

  @doc """
  Traverse errors is a way to retrieve in a plain format the full list of
  errors for all of the schemas and embedded schemas under the main one.
  """
  def traverse_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  Perform a cleaning of a struct converted into a map for all of the
  entries that has no content.
  """
  def clean_data(map) when is_map(map) and not is_struct(map) do
    map
    |> Map.reject(fn {_key, value} -> value in [nil, []] end)
    |> Map.new(fn {key, value} -> {key, clean_data(value)} end)
  end

  def clean_data(list) when is_list(list) do
    list
    |> Enum.reject(&(&1 in [nil, []]))
    |> Enum.map(&clean_data/1)
  end

  def clean_data(otherwise), do: otherwise
end
