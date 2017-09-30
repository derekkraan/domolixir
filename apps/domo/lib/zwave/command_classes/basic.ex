defmodule ZWave.Basic do
  # TODO: implement `basic_report?`

  use ZWave.Constants

  @name "Basic"
  @command_class 0x20
  @basic_set 0x01
  @basic_get 0x02
  @basic_report 0x03

  def commands do
    [
      [:basic_set, :level],
      [:basic_get],
    ]
  end

  def handle({:basic_set, level}, node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x03, @command_class, @basic_set, level], target_node_id: node_id}
  end

  def handle({:basic_get}, node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x02, @command_class, @basic_get], target_node_id: node_id}
  end
end
