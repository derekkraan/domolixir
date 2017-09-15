defmodule ZStick do
  use GenServer

  use ZStick.Constants

  defmodule State, do: defstruct [
    :usb_zstick_pid,
    :command_queue,
    :current_command,
    :controller_node_id,
    :node_bitfield,
  ]

  def start_link do
    GenServer.start_link(__MODULE__, %State{})
  end

  def init(state) do
    {:ok, usb_zstick_pid} = ZStick.UART.connect("/dev/cu.usbmodem1421")
    {:ok, _reader_pid} = ZStick.Reader.start_link(usb_zstick_pid, self())

    state = %{state | usb_zstick_pid: usb_zstick_pid, command_queue: :queue.new(), current_command: nil}

    Process.send_after(self(), :tick, 100)

    {:ok, do_init_sequence(state)}
  end

  def queue_command(command, pid), do: GenServer.cast(pid, {:queue_command, command})

  def handle_cast({:queue_command, command}, state) do
    {:noreply, add_command(state, command)}
  end

  def handle_cast({:message_from_zstick, message}, state) do
    {:noreply, handle_message_from_zstick(message, state)}
  end

  def handle_message_from_zstick(:sendnak, state) do
    require Logger
    Logger.debug "RECEIVED #{:sendnak} |> sending NAK"
    <<@nak>> |> send_msg(state.usb_zstick_pid)
    state
  end

  def handle_message_from_zstick(<<@can>>, state) do
    require Logger
    Logger.debug "RECEIVED CAN"
    send_msg(<<@can>>, state.usb_zstick_pid)
    if state.current_command do
      send_msg(state.current_command, state.usb_zstick_pid)
    end
    state
  end

  def handle_message_from_zstick(message, state) do
    require Logger
    Logger.debug "RECEIVED #{message |> inspect}"
    if message != <<@ack>> do
      Logger.debug("SENDING ACK")
      send_msg(<<@ack>>, state.usb_zstick_pid)
    end

    state = process_message(message, state)

    if ZStick.Msg.required_response?(state.current_command, message) do
      %State{state | current_command: nil}
    else
      state
    end
  end

  def exec_command(state = %State{current_command: nil}), do: state
  def exec_command(state) do
    send_msg(state.current_command, state.usb_zstick_pid)

    if(ZStick.Msg.required_response?(state.current_command, nil)) do
      %State{state | current_command: nil}
    else
      state
    end
  end

  @tick_interval 10

  def handle_info(:tick, state = %State{command_queue: {[], []}, current_command: nil}), do: noop_tick(state)
  def handle_info(:tick, state = %State{current_command: current_command}) when not is_nil(current_command), do: noop_tick(state)
  def handle_info(:tick, state = %State{current_command: nil}) do
    new_state = state
            |> pop_command
            |> exec_command

    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, new_state}
  end

  def noop_tick(state) do
    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, state}
  end

  def add_command(state, command), do: %State{state | command_queue: :queue.in(command, state.command_queue)}

  def pop_command(state) do
    case :queue.out(state.command_queue) do
      {{:value, current_command}, command_queue} -> %State{state | current_command: current_command, command_queue: command_queue}
      {:empty, command_queue} -> %State{state | current_command: nil, command_queue: command_queue}
    end
  end

  def do_init_sequence(state) do
    state
    |> add_command(<<@nak>>)
    |> add_command(%ZStick.Msg{type: @request, function: @func_id_zw_get_version})
    |> add_command(%ZStick.Msg{type: @request, function: @func_id_zw_memory_get_id})
    |> add_command(%ZStick.Msg{type: @request, function: @func_id_zw_get_controller_capabilities})
    |> add_command(%ZStick.Msg{type: @request, function: @func_id_serial_api_get_capabilities})
    |> add_command(%ZStick.Msg{type: @request, function: @func_id_zw_get_suc_node_id})
  end

  defp send_msg(msg, pid) do
    msg
    |> ZStick.Logger.log
    |> ZStick.Msg.prepare
    |> ZStick.UART.write(pid)
  end

  def scan(node\\0)
  def scan(0xff), do: nil
  def scan(node) do
    %ZStick.Msg{type: @request, function: @func_id_zw_request_node_info, data: [node]}
    |> queue_command(self())
    scan(node+1)
  end

  def request_node_states(state, node_id\\0)
  def request_node_states(_state, @max_num_nodes), do: nil
  def request_node_states(state, node_id) do
    use Bitwise
    if state[:node_bitfield] ^^^ (1 <<< node_id) > 0 do
      %ZStick.Msg{type: @request, function: @func_id_zw_get_node_protocol_info, data: [node_id]}
      |> queue_command(self())
    end
    request_node_states(state, node_id + 1)
  end

  def process_message(<<@sof, _length, @response, @func_id_serial_api_get_capabilities, _api_version::size(16), _manufacturer_id::size(16), _product_type::size(16), _product_id::size(16), _api_bitmask::size(256), _checksum>>, state) do
    %ZStick.Msg{type: @request, function: @func_id_zw_get_random} |> queue_command(self())
    %ZStick.Msg{type: @request, function: @func_id_serial_api_get_init_data, data: [state.controller_node_id]} |> queue_command(self())
    %ZStick.Msg{type: @request, function: @func_id_serial_api_appl_node_information, data: [state.controller_node_id]} |> queue_command(self())
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_serial_api_get_init_data, _init_version::size(8), _init_caps::size(8), @num_node_bitfield_bytes, node_bitfield::size(@max_num_nodes), _checksum>>, state) do
    state = %State{state | node_bitfield: node_bitfield}
    request_node_states(state)
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_memory_get_id, controller_node_id::size(40), _checksum>>, state) do
    %State{state | controller_node_id: controller_node_id}
  end

  def process_message(<<@ack>>, state) do
    require Logger
    Logger.debug "ACK received"
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_set_suc_node_id, 1, _checksum>>, state) do
    require Logger
    Logger.debug "SUC Node id successfully set"
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_suc_node_id, 0, _checksum>>, state) do
    %ZStick.Msg{type: @request, function: @func_id_zw_enable_suc, data: [1, @suc_func_nodeid_server]} |> queue_command(self())
    %ZStick.Msg{type: @request, function: @func_id_zw_set_suc_node_id, data: [1, 0, state.controller_node_id]} |> queue_command(self())
    require Logger
    Logger.debug "Setting ourselves as SIS"
    state
  end

  def process_message(<<@sof, _length, @response, @func_id_zw_get_suc_node_id, _suc_node_id, _checksum>>, state) do
    state
  end

  def process_message(message, state) do
    require Logger
    Logger.debug "Unknown message: #{message |> inspect}"
    state
  end
end
