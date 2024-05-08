defmodule Paypal.Case do
  @moduledoc """
  Simulate the Paypal system for replying to the requests.
  """

  def paypal_setup(_args) do
    bypass = Bypass.open()
    Application.put_env(:paypal, :url, endpoint_url(bypass))
    {:ok, bypass: bypass}
  end

  defmacro __using__(_args) do
    quote do
      use ExUnit.Case
      import Paypal.Case

      setup :paypal_setup
    end
  end

  defp endpoint_url(bypass) do
    "http://localhost:#{bypass.port()}"
  end

  def response(conn, code, data \\ []) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(code, Jason.encode!(data))
  end
end
