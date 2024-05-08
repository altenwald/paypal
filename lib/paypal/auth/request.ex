defmodule Paypal.Auth.Request do
  @moduledoc """
  Paypal requires to have an authenticated token to interact. This module
  helps to generate a token time to time (before it's expired) and ensure
  we have always the correct one.
  """
  use Tesla, only: [:post], docs: false

  require Logger

  plug(Tesla.Middleware.Logger,
    format: "$method /api/domains$url?$query ===> $status / time=$time",
    log_level: :debug
  )

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:paypal, :url))

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/x-www-form-urlencoded"},
    {"accept-language", "en_US"}
  ])

  plug(Tesla.Middleware.BasicAuth,
    username: Application.get_env(:paypal, :client_id),
    password: Application.get_env(:paypal, :secret)
  )

  plug(Tesla.Middleware.DecodeJson)

  def auth do
    with {:ok, %_{body: response}} <- post("/v1/oauth2/token", "grant_type=client_credentials") do
      {:ok, response}
    end
  end
end
