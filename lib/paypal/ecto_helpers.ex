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
end
