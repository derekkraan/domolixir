defmodule HueBridge do
  use GenServer

  def start(ip, username) do
    import Supervisor.Spec, warn: false
    worker_spec = [worker(__MODULE__, [ip, username], [id: ip])]

    supervisor_spec = supervisor(Domo.NetworkSupervisor, [worker_spec, [name: network_supervisor_name(ip)]], [id: network_supervisor_name(ip)])

    case Domo.SystemSupervisor.start_child(supervisor_spec) do
      {:ok, _child} -> :ok
      {:error, error} -> IO.inspect(error)
    end
  end

  def start(ip) do
    case Huex.connect(ip) |> Huex.authorize("domolixir#raspberry_pi") do
      %{status: :ok, username: username} -> start(ip, username)
      %{status: :error, error: error} -> IO.inspect(error)
    end
  end

  def start_link(ip, username) do
    GenServer.start_link(__MODULE__, {ip, username}, name: __MODULE__)
  end

  def init({ip, username}) do
    {:ok, Huex.connect(ip, username)}
  end

  def handle_info({:turn_on, light_id}, bridge) do
    Huex.turn_on(bridge, light_id)
    {:noreply, bridge}
  end

  def handle_info({:turn_off, light_id}, bridge) do
    Huex.turn_off(bridge, light_id)
    {:noreply, bridge}
  end

  def network_supervisor_name(ip), do: :"hue_#{ip}_network_supervisor"
end
