defmodule ZWave.CommandClasses do
  require Logger
  use ZWave.Constants

  @command_classes %{
    @command_class_basic =>             ZWave.Basic,
    @command_class_switch_multilevel => ZWave.SwitchMultilevel,
    @command_class_association =>       ZWave.Association,
  }

  def command_class(class), do: @command_classes |> Map.get(class, ZWave.Unsupported)

  defp supports_command?(class, command) do
    class.commands
    |> Enum.map(&List.first/1)
    |> Enum.member?(command |> elem(0))
  end

  def dispatch_command(_command, _node_id, command_classes\\@command_classes |> Map.values)
  def dispatch_command(_command, _node_id, []), do: nil
  def dispatch_command(command, node_id, [command_class | other_command_classes]) do
    if supports_command?(command_class, command) do
      command_class.handle(command, node_id)
    else
      dispatch_command(command, node_id, other_command_classes)
    end
  end
end

defmodule ZWave.Unsupported do
  def commands, do: []
end
