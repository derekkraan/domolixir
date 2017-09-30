defmodule ZWave.CommandClasses do
  require Logger
  use ZWave.Constants

  def command_class(@command_class_basic), do: ZWave.Basic
  def command_class(@command_class_switch_multilevel), do: ZWave.SwitchMultilevel
  def command_class(cmdclass) do
    Logger.debug "TODO: IMPLEMENT COMMAND CLASS #{cmdclass |> inspect}"
    ZWave.Unsupported
  end

  def dispatch_command(_command, _node_id, []), do: nil
  def dispatch_command(command, node_id, [cmd_class_id | cmd_class_ids]) do
    class = command_class(cmd_class_id)
    this_class = class.commands
    |> Enum.map(&List.first/1)
    |> Enum.member?(command |> elem(0))

    if this_class do
      class.handle(command, node_id)
    else
      dispatch_command(command, node_id, cmd_class_ids)
    end
  end
end

defmodule ZWave.Unsupported do
  def commands, do: []
end
