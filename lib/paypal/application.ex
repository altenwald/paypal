defmodule Paypal.Application do
  @moduledoc false
  use Application

  @doc false
  def start(_type, _args) do
    children = [
      {Finch, name: Paypal.Finch},
      Paypal.Auth.Worker
    ]

    opts = [strategy: :one_for_one, name: Paypal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
