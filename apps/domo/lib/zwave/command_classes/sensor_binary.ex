defmodule ZWave.SensorBinary do
  use ZWave.Constants

  @command_class 0x30
  @name "Sensor Binary"

  @sensorbinarycmd_get 0x02
  @sensorbinarycmd_report 0x03

  def start_link(_name, _node_id), do: nil

  def process_message(name, node_id, msg = <<@sof, _msgl, @request, @func_id_application_command_handler, _status, _node_id, _length, @command_class, _rest::binary>>) do
    private_process_message(name, node_id, msg)
  end
  def process_message(_, _, _), do: nil

  def private_process_message(name, node_id, msg = <<@sof, _msglength, @request, @func_id_application_command_handler, _status, node_id, length, @command_class, @sensorbinarycmd_report, value, _checksum>>) do
    %{node_id: node_id, name: name, event_type: "sensor_binary", data: %{value: (if value > 0, do: 1, else: 0)}} |> EventBus.send()
  end

  def commands, do: []

  def add_command_class(state), do: state |> Map.put(:command_classes, [@command_class | state.command_classes])
end
