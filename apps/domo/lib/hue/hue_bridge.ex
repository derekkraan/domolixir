defmodule HueBridge do
  use GenServer

  defstruct [
    :name,
    :ip,
    :username,
    :bridge,
    :label,
    :alive,
  ]

  @init_state %{
    alive: true,
  }

  def start(ip, username) do
    import Supervisor.Spec, warn: false
    worker_spec = [worker(__MODULE__, [ip, username], [id: String.to_atom(ip)])]

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
    GenServer.start_link(__MODULE__, {ip, username}, name: String.to_atom(ip))
  end

  def init({ip, username}) do
    send(self(), :post_init)

    bridge = Huex.connect(ip, username)

    {:ok, %HueBridge{bridge: bridge, ip: ip, username: username}}
  end

  def handle_info(:post_init, state) do
    state.bridge
    |> Huex.lights()
    |> Map.keys()
    |> Enum.each(fn light_id -> Hue.Node.start(String.to_atom(state.ip), light_id) end)

    {:noreply, state}
  end

  def init_lights(bridge) do
  end

  def handle_call({:turn_on, light_id}, _from, state) do
    reply = Huex.turn_on(state.bridge, light_id)
    {:reply, reply, state}
  end

  def handle_call({:turn_off, light_id}, _from, state) do
    reply = Huex.turn_off(state.bridge, light_id)
    {:reply, reply, state}
  end

  def handle_call({:set_brightness, light_id, brightness}, _from, state) do
    reply = Huex.set_brightness(state.bridge, light_id, brightness)
    {:reply, reply, state}
  end

  def network_supervisor_name(ip), do: :"hue_#{ip}_network_supervisor"
end
