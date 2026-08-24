defmodule Paypal.Client do
  @moduledoc """
  Builds the shared `Req.Request` used by all PayPal API modules
  (`Order`, `Payment`, `Subscription`, `Plan`, `Product`).
  """

  alias Paypal.Auth

  @doc """
  Builds a `Req.Request` scoped to the given `path` (e.g. `"/v2/checkout"`).
  """
  @spec new(String.t()) :: Req.Request.t()
  def new(path) do
    base_url = Application.get_env(:paypal, :url, "https://api-m.sandbox.paypal.com") <> path

    [
      base_url: base_url,
      headers: [
        {"content-type", "application/json"},
        {"accept-language", "en_US"},
        {"authorization", "Bearer #{Auth.get_token!()}"}
      ],
      finch: [name: Paypal.Finch],
      retry: false
    ]
    |> Keyword.merge(Application.get_env(:paypal, :req_options, []))
    |> Req.new()
  end
end
