defmodule ZWave.Node do
  require Logger

  use GenServer
  use ZWave.Constants

  defstruct [
    :alive,
    :total_errors,
    :node_id,
    :name,
    :capabilities,
    :basic_class,
    :generic_class,
    :specific_class,
    :command_classes,
    :generic_label,
    :specific_label,
  ]

  def start_link(name, node_id) do
    GenServer.start_link(__MODULE__, {name, node_id}, name: node_name(name, node_id))
  end

  def start(controller_name, node_id) do
    import Supervisor.Spec
    {:ok, _child} = Supervisor.start_child(ZWave.ZStick.network_supervisor_name(controller_name), worker(ZWave.Node, [controller_name, node_id], [id: ZWave.Node.node_name(controller_name, node_id)]))
  end

  def stop(controller_name, node_id) do
    :ok = Supervisor.terminate_child(ZWave.ZStick.network_supervisor_name(controller_name), ZWave.Node.node_name(controller_name, node_id))
    :ok = Supervisor.delete_child(ZWave.ZStick.network_supervisor_name(controller_name), ZWave.Node.node_name(controller_name, node_id))
  end

  def init({name, node_id}) do
    state = %ZWave.Node{alive: true, node_id: node_id, name: name, total_errors: 0}
    request_state(state)
    {:ok, state}
  end

  def node_name(name, node_id), do: :"#{name}_node_#{node_id}"

  defp request_state(state) do
    %ZWave.Msg{type: @request, function: @func_id_zw_get_node_protocol_info, data: [state.node_id], target_node_id: state.node_id}
    |> ZWave.ZStick.queue_command(state.name)
    state
  end

  @association_cmd_groupings_get 0x05

  defp request_association_groupings(state) do
    use Bitwise

    state.command_classes |> Enum.each(fn(command_class) ->
      %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [state.node_id, 0x02, command_class, @association_cmd_groupings_get, @transmit_option_ack ||| @transmit_option_auto_route ||| @transmit_option_explore], target_node_id: state.node_id}
      |> ZWave.ZStick.queue_command(state.name)
    end)
    state
  end

  # -- messages from controller --
  def handle_info({:command, cmd}, state) do
    case ZWave.CommandClasses.dispatch_command(cmd, state.node_id, state.command_classes) do
      nil -> nil
      cmd -> do_cmd(cmd, state)
    end
    {:noreply, state}
  end

  def handle_call(:get_information, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_commands, _from, state) do
    commands = state.command_classes
               |> Enum.flat_map(fn(command_class) -> ZWave.CommandClasses.command_class(command_class).commands end)

    {:reply, commands, state}
  end

  def do_cmd(cmd, state) do
    %ZWave.Msg{cmd | target_node_id: state.node_id} |> ZWave.ZStick.queue_command(state.name)
  end

  # -- messages from ZStick --
  def handle_info({:message_from_zstick, message}, state) do
    state = ZWave.Node.process_message(message, state)
    {:noreply, state}
  end

  def handle_info({:zstick_send_error}, state = %{total_errors: total_errors}) when total_errors > 2 do
    {:noreply, %{state | alive: false, total_errors: state.total_errors + 1}}
  end
  def handle_info({:zstick_send_error}, state) do
    request_state(state)
    {:noreply, %{state | total_errors: state.total_errors + 1}}
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_node_protocol_info, _cap, _freq, _some, _basic, 0, _rest::binary>>, state) do
    %{state | alive: false}
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_node_protocol_info, capabilities, _frequent_listening, _something, basic_class, generic_class, specific_class, _checksum>>, state) do
    %{state |
      alive: true,
      capabilities: capabilities,
      basic_class: basic_class,
      generic_class: generic_class,
      specific_class: specific_class,
    }
    |> Map.merge(OpenZWaveConfig.get_information(generic_class, specific_class))
    |> request_association_groupings()
  end

  def process_message(msg, state) do
    state
  end
end
