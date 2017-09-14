defmodule ZStick do
  use GenServer

  use ZStick.Constants

  defmodule State, do: defstruct [
    :zstick_pid,
    :command_queue,
    :current_command,
    :controller_node_id,
  ]

  def start_link do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  def test, do: GenServer.call(__MODULE__, :test, 10000)

  def init(state) do
    {:ok, zstick_pid} = ZStick.UART.connect
    {:ok, reader_pid} = ZStick.Reader.start_link(zstick_pid)

    state = %{state | zstick_pid: zstick_pid, command_queue: :queue.new(), current_command: nil}

    Process.send_after(self(), :tick, 100)

    {:ok, do_init_sequence(state)}
  end

  def queue_command(command), do: GenServer.cast(__MODULE__, {:queue_command, command})

  def handle_cast({:queue_command, command}, state) do
    {:noreply, %State{state | command_queue: :queue.in(command, state.command_queue)}}
  end

  @tick_interval 10
  def noop_tick(state) do
    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, state}
  end

  def exec_command(state = %State{current_command: nil}), do: state
  def exec_command(state) do
    send_msg(state.current_command, state.zstick_pid)

    if(ZStick.Msg.required_response?(state.current_command, nil)) do
      state = %State{state | current_command: nil}
    else
      state
    end
  end

  def handle_info(:tick, state = %State{command_queue: {[], []}, current_command: nil}), do: noop_tick(state)
  def handle_info(:tick, state = %State{current_command: current_command}) when not is_nil(current_command), do: noop_tick(state)
  def handle_info(:tick, state = %State{current_command: nil}) do
    new_state = state
            |> pop_command
            |> exec_command

    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, new_state}
  end

  def add_command(state, command), do: %State{state | command_queue: :queue.in(command, state.command_queue)}

  def pop_command(state) do
    case :queue.out(state.command_queue) do
      {{:value, current_command}, command_queue} -> %State{state | current_command: current_command, command_queue: command_queue}
      {:empty, command_queue} -> %State{state | current_command: nil, command_queue: command_queue}
    end
  end

  def handle_cast({:message_from_zstick, :sendnak}, state) do
    require Logger
    Logger.debug "RECEIVED #{:sendnak} |> sending NAK"
    <<@nak>> |> send_msg(state.zstick_pid)
    {:noreply, state}
  end

  def handle_cast({:message_from_zstick, <<@can>>}, state) do
    require Logger
    Logger.debug "RECEIVED CAN"
    send_msg(<<@can>>, state.zstick_pid)
    if state.current_command do
      send_msg(state.current_command, state.zstick_pid)
    end
    {:noreply, state}
  end

  def handle_cast({:message_from_zstick, message}, state) do
    require Logger
    Logger.debug "RECEIVED #{message |> inspect}"
    if message != <<@ack>> do
      Logger.debug("SENDING ACK")
      send_msg(<<@ack>>, state.zstick_pid)
    end

    state = process_message(message, state)

    if ZStick.Msg.required_response?(state.current_command, message) do
      {:noreply, %State{state | current_command: nil}}
    else
      {:noreply, state}
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
    |> queue_command
    scan(node+1)
  end

  def process_message(<<@sof, _length, @response, @func_id_serial_api_get_capabilities, api_version::size(16), manufacturer_id::size(16), product_type::size(16), product_id::size(16), api_bitmask::size(256), _checksum>>, state) do
    state
  end
  def process_message(<<@sof, _length, @response, @func_id_serial_api_get_init_data, init_version::size(8), init_caps::size(8), @num_node_bitfield_bytes, node_bitfield::size(232), _checksum>>, state) do
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
    %ZStick.Msg{type: @request, function: @func_id_zw_enable_suc, data: [1, @suc_func_nodeid_server]}
    |> ZStick.queue_command
    %ZStick.Msg{type: @request, function: @func_id_zw_set_suc_node_id, data: [1, 0, state.controller_node_id]}
    |> ZStick.queue_command
    require Logger
    Logger.debug "Setting ourselves as SIS"
    state
  end
  def process_message(<<@sof, _length, @response, @func_id_zw_get_suc_node_id, suc_node_id, _checksum>>, state) do
    state
  end
  def process_message(message, state) do
    require Logger
    Logger.debug "Unknown message: #{message |> inspect}"
    state
  end
end
