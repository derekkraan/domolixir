defmodule ZWave.Basic do
  @command_class 0x20
  @name "Basic"
  # TODO: implement `basic_report?`

  use ZWave.Constants

  def start_link(name, node_id), do: nil

  @basic_set 0x01
  @basic_get 0x02
  @basic_report 0x03

  def commands, do: [
    [:basic_set, :level],
    [:basic_get],
  ]

  def add_command_class(state), do: state |> Map.put(:command_classes, [@command_class | state.command_classes])

  def handle({:basic_set, level}, node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x03, @command_class, @basic_set, level], target_node_id: node_id}
  end

  def handle({:basic_get}, node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x02, @command_class, @basic_get], target_node_id: node_id}
  end

  def process_message(name, node_id, msg = <<@sof, _msgl, @request, @func_id_application_command_handler, _status, _node_id, _length, @command_class, _rest::binary>>) do
    private_process_message(name, node_id, msg)
  end
  def process_message(_, _, _), do: nil

  def private_process_message(name, node_id, msg = <<@sof, _msglength, @request, @func_id_application_command_handler, _status, _node_id, _length, @command_class, @basic_set, value, _rest::binary>>) do
    %{node_id: node_id, name: name, event_type: "basic_set", data: %{value: (if value > 0, do: 1, else: 0)}} |> EventBus.send()
  end
end
