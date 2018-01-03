defmodule Domo.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Domo.Sunrise, []),
      supervisor(Domo.SystemSupervisor, []),
      supervisor(Domo.DiscoverSupervisor, []),
      supervisor(Domo.EventListeners, [[
        worker(Domo.EventListener.EventLog, [], [id: Domo.EventListener.EventLog]),
        worker(Domo.EventListener.Networks, [], [id: Domo.EventListener.Networks]),
        worker(Domo.EventListener.Nodes, [], [id: Domo.EventListener.Nodes]),
      ]]),
      supervisor(Domo.EventGenerators, [[
        worker(Domo.EventGenerator.Clock, [], [id: Domo.EventGenerator.Clock])
      ]]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Domo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
