defmodule ZWave.ZStick do
  require Logger
  use GenServer

  use ZWave.Constants

  defmodule State, do: defstruct [
    :name,
    :usb_zstick_pid,
    :command_queue,
    :current_command,
    :controller_node_id,
    :node_bitfield,
    :current_callback_id,
    :callback_commands,
    :label,
  ]

  def start(usb_device, name) do
    import Supervisor.Spec, warn: false

    worker_spec = [worker(__MODULE__, [usb_device, name], [id: name])]

    supervisor_spec = supervisor(Domo.NetworkSupervisor, [worker_spec, [name: network_supervisor_name(name)]], [id: network_supervisor_name(name)])
    case Domo.SystemSupervisor.start_child(supervisor_spec) do
      {:ok, _child} -> :ok
      {:error, error} -> IO.inspect(error)
    end
  end

  def network_supervisor_name(name), do: :"#{name}_network_supervisor"

  def start_link(usb_device, name) do
    GenServer.start_link(__MODULE__, {usb_device, name}, name: name)
  end

  def handle_call(:get_information, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_commands, _from, state) do
    {:reply, [[:add_device], [:remove_device]], state}
  end

  def init({usb_device, name}) do
    state = %State{name: name, label: name}
    {:ok, usb_zstick_pid} = ZStick.UART.connect(usb_device)
    {:ok, _reader_pid} = ZStick.Reader.start_link(usb_zstick_pid, self())

    state = %{state | usb_zstick_pid: usb_zstick_pid, command_queue: :queue.new(), current_command: nil, current_callback_id: 1, callback_commands: %{}}

    Process.send_after(self(), :tick, 100)

    {:ok, do_init_sequence(state)}
  end

  def supervisor_name(name), do: :"#{name}_supervisor"

  def queue_command(command, pid), do: GenServer.cast(pid, {:queue_command, command})

  def handle_cast({:queue_command, command}, state) do
    {:noreply, add_command(state, command)}
  end

  def handle_cast({:message_from_zstick, message}, state) do
    {:noreply, handle_message_from_zstick(message, state)}
  end

  def handle_info({:remove_device}, state) do
    use Bitwise

    {state, command} = add_callback_id(state, %ZWave.Msg{type: @request, function: @func_id_zw_remove_node_from_network, data: [@remove_node_any]})
    {:noreply, state |> add_command(command)}
  end

  def handle_info({:add_device}, state) do
    use Bitwise
    {state, command} = add_callback_id(state, %ZWave.Msg{type: @request, function: @func_id_zw_add_node_to_network, data: [@add_node_any ||| @option_high_power]})
    {:noreply, state |> add_command(command)}
  end

  def handle_message_from_zstick(:sendnak, state) do
    Logger.debug "RECEIVED #{:sendnak} |> sending NAK"
    <<@nak>> |> send_msg(state.usb_zstick_pid)
    state
  end

  def handle_message_from_zstick(<<@can>>, state) do
    Logger.debug "RECEIVED CAN"
    send_msg(<<@can>>, state.usb_zstick_pid)
    if state.current_command do
      send_msg(state.current_command, state.usb_zstick_pid)
    end
    state
  end

  def handle_message_from_zstick(message, state) do
    Logger.debug "RECEIVED #{message |> inspect}"
    if message != <<@ack>> do
      send_msg(<<@ack>>, state.usb_zstick_pid)
    end

    state = process_message(message, state)

    if ZWave.Msg.required_response?(state.current_command, message) do
      %State{state | current_command: nil}
    else
      state
    end
  end

  def exec_command(state = %State{current_command: nil}), do: state
  def exec_command(state) do
    send_msg(state.current_command, state.usb_zstick_pid)

    if(ZWave.Msg.required_response?(state.current_command, nil)) do
      %State{state | current_command: nil}
    else
      state
    end
  end

  @tick_interval 10

  def handle_info(:tick, state = %State{command_queue: {[], []}, current_command: nil}), do: noop_tick(state)
  def handle_info(:tick, state = %State{current_command: current_command}) when not is_nil(current_command), do: noop_tick(state)
  def handle_info(:tick, state = %State{current_command: nil}) do
    new_state =
      state
      |> pop_command
      |> exec_command

    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, new_state}
  end

  def noop_tick(state) do
    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, state}
  end

  def add_command(state, command) do
    # {state, command} = add_callback_id(state, command)
    Logger.debug "ADDING COMMAND"
    %State{state | command_queue: :queue.in(command, state.command_queue)}
  end

  def add_callback_id(state, command = <<_::binary>>), do: {state, command}
  def add_callback_id(state, command = %{data: nil}), do: {state, command}
  def add_callback_id(state, command) do
    {
      %State{state | current_callback_id: (state.current_callback_id + 1), callback_commands: state.callback_commands |> Map.put(state.current_callback_id, command)},
      %{command | callback_id: state.current_callback_id}
    }
  end

  def pop_command(state) do
    case :queue.out(state.command_queue) do
      {{:value, current_command}, command_queue} -> %State{state | current_command: current_command, command_queue: command_queue}
      {:empty, command_queue} -> %State{state | current_command: nil, command_queue: command_queue}
    end
  end

  def do_init_sequence(state) do
    state
    |> add_command(<<@nak>>)
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_get_version})
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_memory_get_id})
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_get_controller_capabilities})
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_serial_api_get_capabilities})
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_get_suc_node_id})
  end

  defp send_msg(msg, pid) do
    msg
    |> ZWave.Logger.log
    |> ZWave.Msg.prepare
    |> log_msg
    |> ZStick.UART.write(pid)
  end

  def log_msg(msg) do
    Logger.debug "SENDING  #{msg |> inspect}"
    msg
  end

  def process_message(<<@sof, _length, @response, @func_id_serial_api_get_capabilities, _api_version::size(16), _manufacturer_id::size(16), _product_type::size(16), _product_id::size(16), _api_bitmask::size(256), _checksum>>, state) do
    Logger.debug "GOT SERIAL API CAPABILITIES"
    state
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_get_random})
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_serial_api_get_init_data})
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_serial_api_appl_node_information, data: [state.controller_node_id], target_node_id: state.controller_node_id})
  end

  def process_message(<<@sof, _length, @response, @func_id_serial_api_get_init_data, _init_version::size(8), _init_caps::size(8), @num_node_bitfield_bytes, node_bitfield::size(@max_num_nodes), _something, _else, _checksum>>, state) do
    Logger.debug "GOT SERIAL API INIT DATA"
    Logger.debug "node bitfield: #{node_bitfield |> inspect}"

    ZWave.NodeBitmaskParser.nodes_in_bytes(<<node_bitfield::size(@max_num_nodes)>>)
    |> Enum.each(fn(node_id) -> ZWave.Node.start(state.name, node_id) end)

    state
  end

  def process_message(msg = <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, capabilities, _frequent_listening, _something, device_classes::size(24), _checksum>>, state) do
    Process.send(ZWave.Node.node_name(state.name, state.current_command.target_node_id), {:message_from_zstick, msg}, [])
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_random, random, _checksum>>, state), do: state

  def process_message(<<@sof, _length, @response, @func_id_zw_memory_get_id, _home_id::size(32), controller_node_id, _checksum>>, state) do
    Logger.debug "controller node id: #{controller_node_id |> inspect}"
    %State{state | controller_node_id: controller_node_id}
  end

  def process_message(<<@ack>>, state) do
    Logger.debug "ACK received"
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_set_suc_node_id, 1, _checksum>>, state) do
    Logger.debug "SUC Node id successfully set"
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_suc_node_id, 0, _checksum>>, state) do
    Logger.debug "Setting ourselves as SIS"
    state
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_enable_suc, data: [1, @suc_func_nodeid_server]})
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_set_suc_node_id, data: [1, 0, state.controller_node_id], target_node_id: state.controller_node_id})
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_suc_node_id, _suc_node_id, _checksum>>, state) do
    state
  end

  def process_message(<<@sof, _length, @request, @func_id_zw_add_node_to_network, _callback_id, @add_node_status_failed, _rest::binary>>, state) do
    use Bitwise
    state
    |> add_command(%ZWave.Msg{type: @request, function: @func_id_zw_add_node_to_network, data: [@add_node_stop]})
  end

  def process_message(<<@sof, _length, @request, @func_id_zw_add_node_to_network, _callback_id, @add_node_status_adding_slave, node_id, _rest::binary>>, state) do
    ZWave.Node.start(state.name, node_id)
    state
  end

  def process_message(<<@sof, _length, @request, @func_id_zw_remove_node_from_network, _callback_id, @remove_node_status_removing_slave, 0, _rest::binary>>, state) do
    Logger.debug "non-connected device removed"
    state
  end

  def process_message(<<@sof, _length, @request, @func_id_zw_remove_node_from_network, _callback_id, @remove_node_status_removing_slave, node_id, _rest::binary>>, state) do
    ZWave.Node.stop(state.name, node_id)
    state
  end

  def process_message(message, state) do
    Logger.debug "Unknown message: #{message |> inspect}"
    state
  end
end
