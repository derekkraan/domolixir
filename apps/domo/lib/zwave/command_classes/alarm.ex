defmodule ZWave.Alarm do
  use ZWave.Constants

  @command_class 0x71
  @name "Alarm"

  @alarmcmd_get 0x04
  @alarmcmd_report 0x05
  @alarmcmd_supportedget 0x07
  @alarmcmd_supportedreport 0x08

  @alarmindex_type 0
  @alarmindex_level 1
  @alarmindex_sourcenodeid 2

  @alarm_general 0
  @alarm_smoke 1
  @alarm_carbonmonoxide 2
  @alarm_carbondioxide 3
  @alarm_heat 4
  @alarm_flood 5
  @alarm_access_control 6
  @alarm_burglar 7
  @alarm_power_management 8
  @alarm_system 9
  @alarm_emergency 10
  @alarm_clock 11
  @alarm_appliance 12
  @alarm_homehealth 13
  @alarm_count 14

  def start_link(_name, _node_id), do: nil

  def commands, do: []

  def command_class, do: @command_class

  def process_message(
        name,
        node_id,
        msg =
          <<@sof, _msgl, @request, @func_id_application_command_handler, _status, _node_id,
            _length, @command_class, _rest::binary>>
      ) do
    private_process_message(name, node_id, msg)
  end

  def process_message(_, _, _), do: nil

  def private_process_message(
        name,
        node_id,
        msg =
          <<@sof, _msglength, @request, @func_id_application_command_handler, _status, _node_id,
            _length, @command_class, @alarmcmd_report, alarm_type, alarm_level, _rest::binary>>
      ) do
    %{
      node_id: node_id,
      name: name,
      event_type: "alarm",
      data: %{
        alarm_type: alarm_type,
        alarm_type_name: alarm_type_name(alarm_type),
        alarm_level: alarm_level
      }
    }
    |> EventBus.send()
  end

  def alarm_type_name(@alarm_general), do: "General"
  def alarm_type_name(@alarm_smoke), do: "Smoke"
  def alarm_type_name(@alarm_carbonmonoxide), do: "Carbon Monoxide"
  def alarm_type_name(@alarm_carbondioxide), do: "Carbon Dioxide"
  def alarm_type_name(@alarm_heat), do: "Heat"
  def alarm_type_name(@alarm_flood), do: "Flood"
  def alarm_type_name(@alarm_access_control), do: "Access Control"
  def alarm_type_name(@alarm_burglar), do: "Burglar"
  def alarm_type_name(@alarm_power_management), do: "Power Management"
  def alarm_type_name(@alarm_system), do: "System"
  def alarm_type_name(@alarm_emergency), do: "Emergency"
  def alarm_type_name(@alarm_clock), do: "Clock"
  def alarm_type_name(@alarm_appliance), do: "Appliance"
  def alarm_type_name(@alarm_homehealth), do: "HomeHealth"
end
