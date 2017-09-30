defmodule ZWave.SwitchMultilevel do
  @command_class 0x26

  @switchmultilevelcmd_set 0x01
  @switchmultilevelcmd_get 0x02
  @switchmultilevelcmd_report 0x03
  @switchmultilevelcmd_startlevelchange 0x04
  @switchmultilevelcmd_stoplevelchange 0x05
  @switchmultilevelcmd_supportedget 0x06
  @switchmultilevelcmd_supportedreport 0x07

  def commands, do: []
end
