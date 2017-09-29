defmodule Domo.NetworkSupervisor do
  require Logger
  use Supervisor

  def start_link(worker_spec, options) do
    IO.puts "Domo.NetworkSupervisor.start_link #{worker_spec |> inspect}, #{options |> inspect}"
    Supervisor.start_link(__MODULE__, worker_spec, name: options[:name])
  end

  def init(worker_spec) do
    IO.puts "Domo.NetworkSupervisor.init #{worker_spec |> inspect}"
    supervise(worker_spec, strategy: :one_for_one)
  end

  def name(name), do: :"#{name}_network_supervisor"
end
