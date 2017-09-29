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
      # supervisor(ZStick.Nodes, ["/dev/cu.usbmodem1421", :usb1]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Domo.Supervisor]
    out = Supervisor.start_link(children, opts)
    ZStick.start("/dev/cu.usbmodem1421", :usb1)
    out
  end
end

defmodule Domo.SystemSupervisor do
  require Logger
  use Supervisor

  def start_link do
    IO.puts "Domo.SystemSupervisor.start_link"
    Supervisor.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def start_child(defn) do
    IO.puts "Domo.SystemSupervisor.start_child(#{defn |> inspect})"
    Supervisor.start_child(__MODULE__, defn)
  end

  def init(_) do
    IO.puts "Domo.SystemSupervisor.init()"
    supervise([], strategy: :one_for_one)
  end

  def all_nodes do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {name, _pid, _worker, _def} -> name end)
    |> Enum.flat_map(fn(name) ->
      Supervisor.which_children(name) |> Enum.map fn {name, _pid, _worker, _def} -> name end
    end)
  end

  def networks do
    Supervisor.which_children(__MODULE__) |> Enum.map fn {name, _pid, _worker, _def} -> name end
  end
end

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

  def nodes(network) do
    Supervisor.which_children(network) |> Enum.map fn {name, _pid, _worker, _def} -> name end
  end
end

# Domo.SystemSupervisor.networks |> Enum.each fn(network) -> Domo.NetworkSupervisor.nodes(network) end

