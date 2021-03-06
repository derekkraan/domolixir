defmodule ZWave.CommandClasses do
  require Logger
  use ZWave.Constants

  @command_classes %{
    @command_class_basic => ZWave.Basic,
    @command_class_switch_multilevel => ZWave.SwitchMultilevel,
    @command_class_switch_all => ZWave.SwitchAll,
    @command_class_multi_instance => ZWave.MultiInstance,
    @command_class_association => ZWave.Association,
    @command_class_wake_up => ZWave.WakeUp,
    @command_class_sensor_multilevel => ZWave.SensorMultiLevel,
    @command_class_sensor_binary => ZWave.SensorBinary,
    @command_class_meter => ZWave.Meter,
    @command_class_alarm => ZWave.Alarm,
    @command_class_sensor_alarm => ZWave.SensorAlarm
  }

  def command_class(class) do
    class_module =
      @command_classes
      |> Map.get(class, ZWave.Unsupported)

    Logger.debug("command class found: #{inspect(class)} => #{inspect(class_module)}")
    class_module
  end

  defp supports_command?(class, command) do
    class.commands
    |> Enum.map(&List.first/1)
    |> Enum.member?(command |> elem(0))
  end

  def dispatch_command(_command, _node_id, command_classes \\ @command_classes |> Map.values())
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
  require Logger
  def start_link(_node_id, _node_name), do: nil
  def commands, do: []

  def message_from_zstick(msg),
    do: Logger.error("message from ZStick to unsupported command class: #{msg |> inspect}")

  def process_message(_, _, _), do: nil
end
