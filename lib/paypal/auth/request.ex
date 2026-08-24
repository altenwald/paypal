defmodule Paypal.Auth.Request do
  @moduledoc """
  Performs OAuth2 authentication against PayPal to retrieve an access token.
  """
  require Logger

  @doc """
  Perform the authorization and retrieve the response.
  """
  @spec auth() :: {:ok, map()} | {:error, any()}
  def auth do
    base_url = Application.get_env(:paypal, :url, "https://api-m.sandbox.paypal.com")
    client_id = Application.get_env(:paypal, :client_id)
    secret = Application.get_env(:paypal, :secret)

    req =
      [
        base_url: base_url,
        auth: {:basic, "#{client_id}:#{secret}"},
        headers: [
          {"content-type", "application/x-www-form-urlencoded"},
          {"accept-language", "en_US"}
        ],
        finch: [name: Paypal.Finch]
      ]
      |> Keyword.merge(Application.get_env(:paypal, :req_options, []))
      |> Req.new()

    case Req.post(req, url: "/v1/oauth2/token", form: [grant_type: "client_credentials"]) do
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:bad_status, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
