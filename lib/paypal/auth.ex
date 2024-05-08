defmodule Paypal.Auth do
  @moduledoc """
  Paypal requires to have an authenticated token to interact. This module
  helps to generate a token time to time (before it's expired) and ensure
  we have always the correct one.
  """

  @doc """
  Get active token.
  """
  defdelegate get_token, to: Paypal.Auth.Worker

  @doc """
  Get token and fails if there's no token.
  """
  def get_token! do
    {:ok, access_token} = get_token()
    access_token
  end
end
