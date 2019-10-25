defmodule ZWave.SwitchAll do
  @behaviour ZWave.CommandClass

  require Logger

  use ZWave.Constants

  @command_class 0x27

  @switch_all_cmd_set 0x01
  @switch_all_cmd_get 0x02
  @switch_all_cmd_report 0x03
  @switch_all_cmd_on 0x04
  @switch_all_cmd_off 0x05

  # <<1, 7, 0, 19, 15, 0, 0, 2, 230>>
  # <<1, 7, 0, 19, 19, 0, 0, 2, 250>>
  # !!!
  # <<1, 7, 0, 19, 13, 0, 0, 2, 228>>
  # !!!

  def commands, do: [[:switch_all_on], [:switch_all_off], [:switch_all_get], [:switch_all_set]]

  def start_link(name, node_id), do: nil

  def process_message(
        name,
        node_id,
        msg =
          <<@sof, _msgl, @request, @func_id_application_command_handler, _status, _node_id,
            _length, @command_class, _rest::binary>>
      ) do
  end

  def process_message(_, _, _), do: nil

  def command_class, do: @command_class

  def handle({:switch_all_get}, node_id) do
    Logger.debug("switch all get #{inspect(node_id)}")

    %ZWave.Msg{
      type: @request,
      function: @func_id_zw_send_data,
      data: [node_id, 0x02, @command_class, @switch_all_cmd_get],
      target_node_id: node_id,
      expected_response: @func_id_application_command_handler
    }
  end

  def handle({:switch_all_on}, node_id) do
    Logger.debug("switch all on #{inspect(node_id)}")

    %ZWave.Msg{
      type: @request,
      function: @func_id_zw_send_data,
      data: [node_id, 0x02, @command_class, @switch_all_cmd_on],
      target_node_id: node_id
    }
  end

  def handle({:switch_all_off}, node_id) do
    Logger.debug("switch all off #{inspect(node_id)}")

    %ZWave.Msg{
      type: @request,
      function: @func_id_zw_send_data,
      data: [node_id, 0x02, @command_class, @switch_all_cmd_off],
      target_node_id: node_id
    }
  end
end
