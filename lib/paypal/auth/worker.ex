defmodule Paypal.Auth.Worker do
  @moduledoc """
  The worker is performing the refresh of the token.
  """
  use GenServer
  require Logger
  alias Paypal.Auth

  @time_when_fails 5

  @typedoc """
  The internal structure for the auth of Paypal is composed of
  a `access` entry (see `Paypal.Auth.Access.t/0` for further information),
  and `timer_ref`, a reference for the current and active timer.
  """

  @type t() :: %__MODULE__{
          access: nil | Auth.Access.t(),
          timer_ref: nil | reference()
        }

  defstruct access: nil,
            timer_ref: nil

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get the access token stored in the worker.
  """
  @spec get_token() :: {:ok, String.t()} | {:error, any()}
  def get_token, do: GenServer.call(__MODULE__, :get_token)

  @doc """
  Performs a manual refresh for the access token.
  """
  def refresh, do: send(__MODULE__, :refresh)

  @impl GenServer
  @doc false
  def init([]) do
    if Application.get_env(:paypal, :auto_refresh, true) do
      {:ok, %__MODULE__{}, {:continue, :refresh}}
    else
      {:ok, %__MODULE__{}}
    end
  end

  @impl GenServer
  @doc false
  def handle_continue(:refresh, state) do
    if timer_ref = state.timer_ref, do: Process.cancel_timer(timer_ref)

    with {:ok, access_params} <- Auth.Request.auth(),
         {:ok, access} <- Auth.Access.cast(access_params) do
      seconds = access.expires_in
      Logger.info("generated new token that expires in #{seconds} seconds")
      timeout = :timer.seconds(seconds)
      timer_ref = Process.send_after(self(), :refresh, timeout)
      {:noreply, %__MODULE__{state | access: access, timer_ref: timer_ref}}
    else
      {:error, reason} ->
        Logger.error("cannot refresh the token: #{inspect(reason)}")
        timer_ref = Process.send_after(self(), :refresh, :timer.seconds(@time_when_fails))
        {:noreply, %__MODULE__{state | timer_ref: timer_ref}}
    end
  end

  @impl GenServer
  @doc false
  def handle_call(:get_token, _from, %__MODULE__{access: nil} = state) do
    {:reply, {:error, :notfound}, state}
  end

  def handle_call(:get_token, _from, state) do
    {:reply, {:ok, state.access.access_token}, state}
  end

  @impl GenServer
  def handle_info(:refresh, state) do
    {:noreply, state, {:continue, :refresh}}
  end
end
