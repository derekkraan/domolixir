defmodule ZWave.NoOperation do
  use ZWave.Constants

  @command_class 0x00
  @name "No Operation (noop)"

  def start_link(_name, _node_id), do: nil

  def commands, do: []

  def add_command_class(state), do: state |> Map.put(:command_clases, [@command_class | state.command_classes])
  def process_message(_name, _node_id, _msg), do: nil

  def noop_command(node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x02, @command_class, 0, @transmit_options], target_node_id: node_id}
  end
end
