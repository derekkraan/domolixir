defmodule Domo.NetworkSupervisor do
  require Logger
  use Supervisor

  def start_link(worker_spec, options) do
    Supervisor.start_link(__MODULE__, worker_spec, name: options[:name])
  end

  def init(worker_spec) do
    supervise(worker_spec, strategy: :one_for_one)
  end

  def name(name), do: :"#{name}_network_supervisor"
end
