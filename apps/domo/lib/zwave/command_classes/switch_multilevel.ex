defmodule ZWave.SwitchMultilevel do
  @command_class 0x26
  @name "Switch Multi-level"

  use ZWave.Constants

  def start_link(name, node_id), do: nil

  def process_message(_, _, _), do: nil

  @switchmultilevelcmd_set 0x01
  @switchmultilevelcmd_get 0x02
  @switchmultilevelcmd_report 0x03
  @switchmultilevelcmd_startlevelchange 0x04
  @switchmultilevelcmd_stoplevelchange 0x05
  @switchmultilevelcmd_supportedget 0x06
  @switchmultilevelcmd_supportedreport 0x07

  def commands,
    do: [
      [:switch_multilevel_set, [:level, :integer_0_100], [:duration, :seconds]],
      [:switch_multilevel_supported_get]
    ]

  def handle({:switch_multilevel_set, level, duration}, node_id) do
    %ZWave.Msg{
      type: @request,
      function: @func_id_zw_send_data,
      data: [node_id, 0x04, @command_class, @switchmultilevelcmd_set, level, duration]
    }
  end

  def handle({:switch_multilevel_supported_get}, node_id) do
    %ZWave.Msg{
      type: @request,
      function: @func_id_zw_send_data,
      data: [node_id, 0x02, @command_class, @switchmultilevelcmd_supportedget]
    }
  end
end
