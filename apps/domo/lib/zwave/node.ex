defmodule ZWave.Node do
  require Logger

  use GenServer
  use ZWave.Constants

  defstruct [
    :alive,
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
    IO.puts "START NODE #{node_id}"
    {:ok, _child} = Supervisor.start_child(ZWave.ZStick.network_supervisor_name(controller_name), worker(ZWave.Node, [controller_name, node_id], [id: ZWave.Node.node_name(controller_name, node_id)]))
  end

  def stop(controller_name, node_id) do
    IO.puts "STOPPING NODE #{node_id}"
    :ok = Supervisor.terminate_child(ZWave.ZStick.network_supervisor_name(controller_name), ZWave.Node.node_name(controller_name, node_id))
    :ok = Supervisor.delete_child(ZWave.ZStick.network_supervisor_name(controller_name), ZWave.Node.node_name(controller_name, node_id))
  end

  def init({name, node_id}) do
    state = %ZWave.Node{alive: true, node_id: node_id, name: name}
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

    IO.inspect state
    IO.inspect state.command_classes
    state.command_classes |> Enum.each(fn(command_class) ->
      %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [state.node_id, 0x02, command_class, @association_cmd_groupings_get, @transmit_option_ack ||| @transmit_option_auto_route ||| @transmit_option_explore], target_node_id: state.node_id}
      |> ZWave.ZStick.queue_command(state.name)
    end)
    state
  end

  def handle_info({:message_from_zstick, message}, state) do
    {:noreply, ZWave.Node.process_message(message, state)}
  end

  def handle_info({:zstick_send_error}, state) do
    {:noreply, %{state | alive: false}}
  end

  @command_class_basic 0x20
  @basic_set 0x01

  @command_class_switch_multilevel 0x26
  @switchmultilevelcmd_set 0x01
  @switchmultilevelcmd_get 0x02
  @switchmultilevelcmd_report 0x03
  @switchmultilevelcmd_startlevelchange 0x04
  @switchmultilevelcmd_stoplevelchange 0x05
  @switchmultilevelcmd_supportedget 0x06
  @switchmultilevelcmd_supportedreport 0x07

  def handle_info({:set_basic, level}, state) do
    Logger.debug "SETTING LEVEL #{level |> inspect}"
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [state.node_id, 0x03, @command_class_basic, @basic_set, level]} |> do_cmd(state)
    {:noreply, state}
  end

  def handle_call(:get_information, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_commands, _from, state) do
    commands = [
      [:basic, :turn_on],
      [:basic, :turn_off],
      [:multilevel, :set_value, :value, :duration],
    ]
    {:reply, commands, state}
  end

  def handle_info({:set_level, level, duration}, state) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [state.node_id, 0x04, @command_class_switch_multilevel, @switchmultilevelcmd_set, level, duration]} |> do_cmd(state)
    {:noreply, state}
  end

  def do_cmd(cmd, state) do
    Logger.debug "SENDING COMMAND"
    %ZWave.Msg{cmd | target_node_id: state.node_id} |> ZWave.ZStick.queue_command(state.name)
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_node_protocol_info, _cap, _freq, _some, _basic, 0, _rest::binary>>, state) do
    %{state | alive: false}
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_node_protocol_info, capabilities, _frequent_listening, _something, basic_class, generic_class, specific_class, _checksum>>, state) do
    IO.inspect(capabilities)
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

  def basic_class(%{basic_class: 1}), do: :controller
  def basic_class(%{basic_class: 2}), do: :static_controller
  def basic_class(%{basic_class: 3}), do: :slave
  def basic_class(%{basic_class: 4}), do: :routing_slave
end
