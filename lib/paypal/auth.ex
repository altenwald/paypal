defmodule Paypal.Auth do
  @moduledoc """
  PayPal requires an authenticated OAuth2 token to interact with the API. This module
  helps manage and retrieve tokens, ensuring the token is kept active and automatically
  refreshed in the background before expiry.

  ## Configuration

  ```elixir
  config :paypal,
    url: System.get_env("PAYPAL_URL", "https://api-m.sandbox.paypal.com"),
    client_id: System.get_env("PAYPAL_CLIENT_ID"),
    secret: System.get_env("PAYPAL_SECRET")
  ```

  The configuration parameters are:

  - `url` - The base URL for PayPal API requests (sandbox or production).
  - `client_id` - The client ID provided in the PayPal Developer Dashboard.
  - `secret` - The secret key provided in the PayPal Developer Dashboard.
  """

  @doc """
  Get active token.
  """
  @spec get_token() :: {:ok, String.t()} | {:error, any()}
  defdelegate get_token, to: Paypal.Auth.Worker

  @doc """
  Get token and fails if there's no token.
  """
  @spec get_token!() :: String.t()
  def get_token! do
    {:ok, access_token} = get_token()
    access_token
  end
end
