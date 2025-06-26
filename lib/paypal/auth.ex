defmodule Paypal.Auth do
  @moduledoc """
  Paypal requires to have an authenticated token to interact. This module
  helps to generate a token time to time (before it's expired) and ensure
  we have always the correct one.

  To achieve this, we need a bit of configuration. We could provide this
  adding in our project the following block:

  ```elixir
  config :paypal,
    url: System.get_env("PAYPAL_URL", "https://api-m.sandbox.paypal.com"),
    client_id: System.get_env("PAYPAL_CLIENT_ID"),
    secret: System.get_env("PAYPAL_SECRET")
  ```

  Because the content of the `client_id` and `secret` are sensitive, I prefer
  provide these values using the environment variables, but if you need to
  put them in your config file for your project, go ahead.

  The configuration parameters are the following:

  - `url` is the URL where we have to perform the base requests. Paypal has
    two different URLs and you can see in the example above the one that's
    in use for the sandbox/testing environment. This is the one you should
    use for development.
  - `client_id` is one of the data Paypal provide us when we generate the
    API data to be connected to them.
  - `secret` this is the most sensitive one. If that's unveil, go to the
    Paypal website and regenerate a new one!
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
