defmodule Domo.DiscoverSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def init(_) do
    import Supervisor.Spec, warn: false

    workers = [
      worker(ZWave.Discover, [], [id: ZWave.Discover]),
      worker(Hue.Discover, [], [id: Hue.Discover])
    ]

    supervise(workers, strategy: :one_for_one)
  end
end
