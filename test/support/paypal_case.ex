defmodule Paypal.Case do
  @moduledoc """
  Simulate the Paypal system for replying to the requests.
  """

  def paypal_setup(_args) do
    bypass = Bypass.open()
    Application.put_env(:paypal, :url, endpoint_url(bypass))
    set_token("ACCESSTOKEN")
    {:ok, bypass: bypass}
  end

  @doc """
  Set an active token in the Paypal.Auth.Worker for testing.
  """
  def set_token(token \\ "ACCESSTOKEN") do
    access = %Paypal.Auth.Access{
      access_token: token,
      token_type: "Bearer",
      app_id: "APP-ID",
      expires_in: 3600,
      nonce: "NONCE",
      scope: ""
    }

    if pid = Process.whereis(Paypal.Auth.Worker) do
      :sys.replace_state(pid, fn state -> %{state | access: access} end)
    end

    :ok
  end

  @doc """
  Clear the active token in the Paypal.Auth.Worker for testing unauthenticated state.
  """
  def clear_token do
    if pid = Process.whereis(Paypal.Auth.Worker) do
      :sys.replace_state(pid, fn state -> %{state | access: nil} end)
    end

    :ok
  end

  defmacro __using__(_args) do
    quote do
      use ExUnit.Case
      import Paypal.Case

      setup :paypal_setup
    end
  end

  defp endpoint_url(bypass) do
    "http://localhost:#{bypass.port}"
  end

  def response(conn, code, data \\ nil)

  def response(conn, code, nil) do
    Plug.Conn.resp(conn, code, [])
  end

  def response(conn, code, data) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(code, Jason.encode!(data))
  end
end
