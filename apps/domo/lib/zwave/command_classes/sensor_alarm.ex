defmodule ZWave.SensorAlarm do
  use ZWave.Constants

  @command_class 0x9c
  @name "Sensor Alarm"

  @sensoralarmcmd_get 0x01
  @sensoralarmcmd_report 0x02
  @sensoralarmcmd_supportedget 0x03
  @sensoralarmcmd_supportedreport 0x04

  def start_link(_name, _node_id), do: nil

  def commands, do: []

  def command_class, do: @command_class

  def process_message(name, node_id, msg = <<@sof, _msgl, @request, @func_id_application_command_handler, _status, _node_id, _length, @command_class, _rest::binary>>) do
    private_process_message(name, node_id, msg)
  end
  def process_message(_, _, _), do: nil

  def private_process_message(name, node_id, msg = <<@sof, _msglength, @request, @func_id_application_command_handler, _status, _node_id, _length, @command_class, @sensoralarmcmd_report, source_node_id, value, _rest::binary>>) do
    %{node_id: node_id, name: name, event_type: "sensor_alarm", data: %{source_node_id: source_node_id, value: value}} |> EventBus.send()
  end
end
