defmodule ZStick do
  use GenServer

  use ZStick.Constants

  defmodule State, do: defstruct [
    :zstick_pid,
    :command_queue,
    :current_command,
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

  def queue_command(command), do: GenServer.call(__MODULE__, {:queue_command, command})

  def handle_call({:queue_command, command}, _from, state) do
    {:reply, :ok, %State{state | command_queue: :queue.in(command, state.command_queue)}}
  end

  @tick_interval 200
  def noop_tick(state) do
    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, state}
  end

  def handle_info(:tick, state = %State{command_queue: {[], []}, current_command: nil}), do: noop_tick(state)
  def handle_info(:tick, state = %State{current_command: nil}) do
    state = pop_command(state)


    state =
      if state.current_command do
        send_msg(state.current_command, state.zstick_pid)
        if(ZStick.Msg.required_response?(state.current_command, nil)) do
          state = %State{state | current_command: nil}
        else
          state
        end
      else
        state
      end

    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, state}
  end
  def handle_info(:tick, state), do: noop_tick(state)

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
      send_msg(<<@ack>>, state.zstick_pid)
    end
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
end
