defmodule ZWave.Association do
  @command_class 0x85
  @name "Association"

  use ZWave.Constants
  require Logger

  @associationcmd_set 0x01
  @associationcmd_get 0x02
  @associationcmd_report 0x03
  @associationcmd_remove 0x04
  @associationcmd_groupingsget 0x05
  @associationcmd_groupingsreport 0x06

  def commands, do: [
    [:association_groupings_get],
  ]

  def handle({:association_groupings_get}, node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x02, @command_class, @associationcmd_groupingsget], target_node_id: node_id, expected_response: @func_id_application_command_handler}
  end

  def message_from_zstick(<<@sof, _length, @request, @func_id_application_command_handler, _callback_id, node_id, 3, @command_class, @associationcmd_groupingsreport, num_groups, _checksum>>) do
    Logger.debug "Number of association groups for #{node_id} is #{num_groups}"
    %{number_association_groups: num_groups}
  end
end
