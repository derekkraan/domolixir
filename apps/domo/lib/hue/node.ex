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
    request_state(state)
    {:ok, state}
  end

  defp commands do
    [
      [:turn_on],
      [:turn_off],
      [:set_brightness, [:brightness, :float_0_1]],
    ]
  end

  def request_state(state), do: nil

  def node_name(name, node_id), do: :"#{name}_node_#{node_id}"

  def handle_call({:set_brightness, brightness}, _from, state) do
    result = GenServer.call(state.name, {:set_brightness, state.node_id, brightness})
    {:reply, result, state}
  end

  def handle_call({:turn_on}, _from, state) do
    result = GenServer.call(state.name, {:turn_on, state.node_id})
    {:reply, result, state}
  end

  def handle_call({:turn_off}, _from, state) do
    result = GenServer.call(state.name, {:turn_off, state.node_id})
    {:reply, result, state}
  end
end
