defmodule Hue.Node do
  require Logger

  use GenServer

  @init_state %{
    alive: true,
  }

  defstruct [
    :node_id,
    :name,
    :label,
    :alive,
  ]

  def start_link(name, node_id) do
    GenServer.start_link(__MODULE__, {name, node_id}, name: node_name(name, node_id))
  end

  def start(controller_name, node_id) do
    import Supervisor.Spec
    case Supervisor.start_child(HueBridge.network_supervisor_name(controller_name), worker(__MODULE__, [controller_name, node_id], [id: __MODULE__.node_name(controller_name, node_id)])) do
      {:ok, _child} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      error -> error |> IO.inspect
    end
  end

  def init({name, node_id}) do
    state = %Hue.Node{} |> Map.merge(@init_state) |> Map.merge(%{node_id: node_id, name: name})
    %{event_type: "node_added", network_identifier: name, node_identifier: node_name(name, node_id), commands: commands} |> EventBus.send()
    send(self(), :post_init)
    {:ok, state}
  end

  def handle_info(:post_init, state) do
    {:noreply, request_state(state)}
  end

  defp commands do
    [
      [:turn_on],
      [:turn_off],
      [:set_brightness, [:brightness, :float_0_1]],
    ]
  end

  def request_state(state) do
    node_identifier = node_name(state.name, state.node_id)
    light_info = GenServer.call(state.name, {:command, {:light_info, state.node_id}}) |> IO.inspect
    if(light_info["state"]["on"]) do
      %{event_type: "node_on", node_identifier: node_identifier} |> EventBus.send()
    else
      %{event_type: "node_off", node_identifier: node_identifier} |> EventBus.send()
    end
    %{event_type: "brightness_level", node_identifier: node_identifier, brightness_level: light_info["state"]["bri"] / 255} |> EventBus.send()
    %{event_type: "node_alive", node_identifier: node_identifier, alive: light_info["state"]["reachable"]} |> EventBus.send()
    %{event_type: "node_name", node_identifier: node_identifier, name: light_info["name"]} |> EventBus.send()
    %{event_type: "node_type", node_identifier: node_identifier, type: light_info["type"]} |> EventBus.send()
    state
  end

  def node_name(name, node_id), do: :"#{name}_node_#{node_id}"

  def handle_call({:command, {:set_brightness, brightness}}, _from, state) do
    %{status: :ok} = GenServer.call(state.name, {:command, {:set_brightness, state.node_id, brightness}})
    {:reply, :ok, request_state(state)}
  end

  def handle_call({:command, {:turn_on}}, _from, state) do
    %{status: :ok} = GenServer.call(state.name, {:command, {:turn_on, state.node_id}})
    {:reply, :ok, request_state(state)}
  end

  def handle_call({:command, {:turn_off}}, _from, state) do
    %{status: :ok} = GenServer.call(state.name, {:command, {:turn_off, state.node_id}})
    {:reply, :ok, request_state(state)}
  end
end
