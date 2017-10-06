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
    :listening,
    :frequent_listening,
    :basic_class,
    :generic_class,
    :specific_class,
    :command_classes,
    :command_class_modules,
    :generic_label,
    :specific_label,
    :number_association_groups,
  ]

  @init_state %{
    alive: true,
    total_errors: 0,
    command_classes: [],
    command_class_modules: [],
  }

  @securityflag_security 0x01
  @securityflag_controller 0x02
  @securityflag_specificdevice 0x04
  @securityflag_routingslave 0x08
  @securityflag_beamcapability 0x10
  @securityflag_sensor250ms 0x20
  @securityflag_sensor1000ms 0x40
  @securityflag_optionalfunctionality 0x80

  def start_link(name, node_id) do
    GenServer.start_link(__MODULE__, {name, node_id}, name: node_name(name, node_id))
  end

  def start(controller_name, node_id) do
    import Supervisor.Spec
    case Supervisor.start_child(ZWave.ZStick.network_supervisor_name(controller_name), worker(ZWave.Node, [controller_name, node_id], [id: ZWave.Node.node_name(controller_name, node_id)])) do
      {:ok, _child} -> :ok
      {:error, :already_started} -> :ok
      error -> error
    end
  end

  def stop(controller_name, node_id) do
    :ok = Supervisor.terminate_child(ZWave.ZStick.network_supervisor_name(controller_name), ZWave.Node.node_name(controller_name, node_id))
    :ok = Supervisor.delete_child(ZWave.ZStick.network_supervisor_name(controller_name), ZWave.Node.node_name(controller_name, node_id))
  end

  def init({name, node_id}) do
    state = %ZWave.Node{} |> Map.merge(@init_state) |> Map.merge(%{node_id: node_id, name: name})
    request_state(state)
    {:ok, state}
  end

  def node_name(name, node_id), do: :"#{name}_node_#{node_id}"

  defp request_state(state) do
    %ZWave.Msg{type: @request, function: @func_id_zw_get_node_protocol_info, data: [state.node_id], target_node_id: state.node_id}
    |> ZWave.ZStick.queue_command(state.name)
    state
  end

  #
  # -- messages from controller --
  #
  def handle_info({:command, cmd}, state) do
    IO.puts "RECEIVED COMMAND #{cmd |> inspect}"
    case ZWave.CommandClasses.dispatch_command(cmd, state.node_id) do
      nil -> nil
      cmd -> do_cmd(cmd, state)
    end
    {:noreply, state}
  end

  def handle_info({:update_state, %ZWave.Node{number_association_groups: number_association_groups}}, state) do
    %{controller_node_id: controller_node_id} = GenServer.call(state.name, :get_information)
    (1..number_association_groups) |> Enum.each(fn(group_id) ->
      Logger.debug "setting association #{group_id}"
      ZWave.CommandClasses.dispatch_command({:association_set, controller_node_id, group_id}, state.node_id) |> do_cmd(state)
    end)
    {:noreply, %ZWave.Node{state | number_association_groups: number_association_groups}}
  end
  def handle_info({:update_state, new_state = %ZWave.Node{}}, state) do
    {:noreply, state |> Map.merge(new_state)}
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
    %ZWave.Msg{cmd | target_node_id: state.node_id}  # TODO: is setting target_node_id correct here?
    |> ZWave.ZStick.queue_command(state.name)
  end

  #
  # -- messages from ZStick --
  #
  def handle_info({:message_from_zstick, message}, state) do
    state = ZWave.Node.process_message(state, message)
    state.command_class_modules |> Enum.map(fn(module) ->
      module.process_message(state.name, state.node_id, message)
    end)
    {:noreply, state}
  end

  def handle_info({:zstick_send_error}, state = %{total_errors: total_errors}) when total_errors > 2 do
    {:noreply, %{state | alive: false, total_errors: state.total_errors + 1}}
  end
  def handle_info({:zstick_send_error}, state) do
    request_state(state)
    {:noreply, %{state | total_errors: state.total_errors + 1}}
  end

  def process_message(state, <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, _cap, _freq, _some, _basic, 0, _rest::binary>>) do
    %{state | alive: false}
  end

  def process_message(state, <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, capabilities, frequent_listening, _something, basic_class, generic_class, specific_class, _checksum>>) do
    use Bitwise

    %ZWave.Node{state |
      alive: true,
      listening: capabilities &&& 0x80,
      frequent_listening: frequent_listening &&& (@securityflag_sensor250ms ^^^ @securityflag_sensor1000ms),
      capabilities: capabilities,
      basic_class: basic_class,
      generic_class: generic_class,
      specific_class: specific_class,
    }
    |> Map.merge(OpenZWaveConfig.get_information(generic_class, specific_class))
    |> ZWave.WakeUp.add_command_class()
    |> add_command_class_modules()
    |> start_command_class_modules()
  end

  def process_message(state, _msg), do: state

  def add_command_class_modules(state), do: add_command_class_modules(state, state.command_classes)
  def add_command_class_modules(state, []), do: state
  def add_command_class_modules(state, [command_class | command_classes]) do
    Map.put(state, :command_class_modules, [ZWave.CommandClasses.command_class(command_class) | state.command_class_modules])
    |> add_command_class_modules(command_classes)
  end

  def start_command_class_modules(state), do: start_command_class_modules(state, state.command_class_modules)
  def start_command_class_modules(state, []), do: state
  def start_command_class_modules(state, [module | modules]) do
    module.start_link(state.name, state.node_id)
    start_command_class_modules(state, modules)
  end
end
