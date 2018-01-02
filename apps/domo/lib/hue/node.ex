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
    request_state(state)
    {:ok, state}
  end

  def request_state(state), do: nil

  def node_name(name, node_id), do: :"#{name}_node_#{node_id}"

  def handle_call(:get_information, _from, state) do
    {:reply, %{state | label: "Hue Lamp: #{state.node_id}"}, state}
  end

  def handle_call(:get_commands, _from, state) do
    {:reply, [], state}
  end
end
