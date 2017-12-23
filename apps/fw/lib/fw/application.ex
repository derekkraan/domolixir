defmodule Fw.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    require Logger
    Logger.debug "OPTIONS0"
    inspect(Application.get_all_env(:mdns_configuration)) |> Logger.debug

    # Define workers and child supervisors to be supervised
    children = [
      worker(Fw.Mdns, [Map.new(Application.get_all_env(:mdns_configuration))]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fw.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
