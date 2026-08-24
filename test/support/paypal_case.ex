defmodule Paypal.Case do
  @moduledoc """
  Req.Test helpers and mocks for Paypal testing.
  """

  def paypal_setup(_args) do
    Req.Test.set_req_test_to_shared()
    set_token("ACCESSTOKEN")
    :ok
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

  @doc """
  Adds an expectation that will be called for any incoming request.
  """
  def expect(fun) when is_function(fun, 1) do
    Req.Test.stub(Paypal, fun)
  end

  @doc """
  Adds an expectation that will be called for a specific method and path.
  """
  def expect(method, path, fun) when is_function(fun, 1) do
    Req.Test.stub(Paypal, fn conn ->
      if method && conn.method != normalize_method(method) do
        raise "Expected method #{normalize_method(method)}, got #{conn.method}"
      end

      if path && conn.request_path != path do
        raise "Expected path #{path}, got #{conn.request_path}"
      end

      fun.(conn)
    end)
  end

  @doc """
  Adds an expectation that will be called at most once for any request.
  """
  def expect_once(fun) when is_function(fun, 1) do
    Req.Test.expect(Paypal, 1, fun)
  end

  @doc """
  Adds an expectation that will be called at most once for a specific method and path.
  """
  def expect_once(method, path, fun) when is_function(fun, 1) do
    Req.Test.expect(Paypal, 1, fn conn ->
      if method && conn.method != normalize_method(method) do
        raise "Expected method #{normalize_method(method)}, got #{conn.method}"
      end

      if path && conn.request_path != path do
        raise "Expected path #{path}, got #{conn.request_path}"
      end

      fun.(conn)
    end)
  end

  @doc """
  Sends a response with the given status code and optional body.
  """
  def response(conn, code, data \\ nil)

  def response(conn, code, nil) do
    Plug.Conn.send_resp(conn, code, "")
  end

  def response(conn, code, data) when is_binary(data) do
    conn
    |> Plug.Conn.put_status(code)
    |> Plug.Conn.send_resp(code, data)
  end

  def response(conn, code, data) do
    conn
    |> Plug.Conn.put_status(code)
    |> Req.Test.json(data)
  end

  defp normalize_method(atom) when is_atom(atom), do: atom |> Atom.to_string() |> String.upcase()
  defp normalize_method(binary) when is_binary(binary), do: binary
end
