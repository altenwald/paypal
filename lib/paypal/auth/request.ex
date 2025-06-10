defmodule Paypal.Auth.Request do
  @moduledoc """
  Paypal requires to have an authenticated token to interact. This module
  helps to generate a token time to time (before it's expired) and ensure
  we have always the correct one.
  """
  require Logger

  defp client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [
      {Tesla.Middleware.Logger,
       format: "$method $url ===> $status / time=$time", log_level: :debug},
      {Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url)},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/x-www-form-urlencoded"},
         {"accept-language", "en_US"}
       ]},
      {Tesla.Middleware.BasicAuth,
       username: Application.get_env(:paypal, :client_id),
       password: Application.get_env(:paypal, :secret)},
      Tesla.Middleware.DecodeJson
    ]
  end

  defp adapter do
    {Tesla.Adapter.Finch, name: Paypal.Finch}
  end

  defp post(uri, body), do: Tesla.post(client(), uri, body)

  @doc """
  Perform the authorization and retrieve the response.
  """
  def auth do
    with {:ok, %_{body: response}} <- post("/v1/oauth2/token", "grant_type=client_credentials") do
      {:ok, response}
    end
  end
end
