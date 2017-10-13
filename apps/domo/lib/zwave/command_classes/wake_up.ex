defmodule ZWave.WakeUp do
  use ZWave.Constants
  use GenServer

  @command_class 0x84
  @name "Wake Up"

  require Logger

  defmodule State, do: defstruct [:name, :node_id, :awake, :command_queue]
  @init_state %{awake: true}

  def start_link(name, node_id), do: GenServer.start_link(__MODULE__, {name, node_id}, name: process_name(name, node_id)) |> IO.inspect

  def init({name, node_id}) do
    state = %State{} |> Map.merge(@init_state) |> Map.merge(%{node_id: node_id, name: name, command_queue: :queue.new()})
    wakeup_get_interval_command(node_id) |> ZWave.ZStick.queue_command(name)
    wakeup_no_more_information_command(node_id) |> ZWave.ZStick.queue_command(name)
    wakeup_command_interval_report(node_id) |> ZWave.ZStick.queue_command(name)
    {:ok, state}
  end

  def process_name(name, node_id), do: :"#{ZWave.Node.node_name(name, node_id)}_wake_up_command_class"

  def commands, do: [
    [:wakeup_get_interval],
  ]

  def add_command_class(state = %{listening: 0}), do: state |> Map.put(:command_classes, [@command_class | state.command_classes])
  def add_command_class(state), do: state

  @wakeup_cmd_interval_set 0x04
  @wakeup_cmd_interval_get 0x05
  @wakeup_cmd_interval_report 0x06
  @wakeup_cmd_notification  0x07
  @wakeup_cmd_no_more_information 0x08
  @wakeup_cmd_interval_capabilities_get 0x09
  @wakeup_cmd_interval_capabilities_report 0x0A

  def handle({:wakeup_get_interval}, node_id), do: wakeup_get_interval_command(node_id)

  def wakeup_get_interval_command(node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x02, @command_class, @wakeup_cmd_interval_get, @transmit_options], target_node_id: node_id, expected_response: @func_id_application_command_handler}
  end

  def wakeup_no_more_information_command(node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x02, @command_class, @wakeup_cmd_no_more_information, @transmit_options], target_node_id: node_id, expected_response: @func_id_application_command_handler}
  end

  def wakeup_command_interval_report(node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x02, @command_class, @wakeup_cmd_interval_report, @transmit_options], target_node_id: node_id, expected_response: @func_id_application_command_handler}
  end

  def process_message(name, node_id, message), do: Process.send(process_name(name, node_id), {:message_from_zstick, message}, [])

  def send_commands(state = %{awake: true}) do
    case :queue.out(state.command_queue) do
      {{:value, current_command}, command_queue} ->
        current_command |> ZWave.ZStick.queue_command(state.name)
        %State{state | command_queue: command_queue}
      {:empty, command_queue} ->
        wakeup_no_more_information_command(state.node_id) |> ZWave.ZStick.queue_command(state.name)
        %State{state | command_queue: command_queue, awake: false}
    end
  end
  def send_commands(state), do: state

  def handle_info({:message_from_zstick, message}, state) do
    {:noreply, private_process_message(state, message) |> send_commands()}
  end

  def queue_command(state, command) do
    %State{state | command_queue: :queue.in(command, state.command_queue)}
  end

  def handle_info({:queue_command, command}, state) do
    {:noreply, state |> queue_command(command)}
  end

  def private_process_message(state, <<@sof, _length, @response, @func_id_zw_send_data, 0, _rest::binary>>) do
    %State{state | awake: false} |> IO.inspect
  end

  def private_process_message(state, <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, _rest::binary>>) do
    %State{state | awake: true} |> IO.inspect
  end

  def private_process_message(state, <<@sof, _length, @request, @func_id_application_command_handler, _status, node_id, _length2, @command_class, @wakeup_cmd_notification, _checksum>>) do
    %State{state | awake: true} |> IO.inspect
  end

  def private_process_message(state, <<@sof, _length, @response, @func_id_application_command_handler, 0, @wakeup_cmd_interval_capabilities_report, _rest::binary>>) do
    "DO WE EVER GET HERE" |> IO.inspect
    %State{state | awake: true} |> IO.inspect
  end

  def private_process_message(state, _message), do: state
end
