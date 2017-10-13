defmodule ZWave.SensorMultiLevel do
  use ZWave.Constants

  @command_class 0x31
  @name "Sensor Multi Level"
  @sensormultilevelcmd_supportedget  0x01
  @sensormultilevelcmd_supportedreport 0x02
  @sensormultilevelcmd_get      0x04
  @sensormultilevelcmd_report   0x05

  @sensortype_temperature 1
  @sensortype_general 2
  @sensortype_luminance 3
  @sensortype_power 4
  @sensortype_relativehumidity 5
  @sensortype_velocity 6
  @sensortype_direction 7
  @sensortype_atmosphericpressure 8
  @sensortype_barometricpressure 9
  @sensortype_solarradiation 10
  @sensortype_dewpoint 11
  @sensortype_rainrate 12
  @sensortype_tidelevel 13
  @sensortype_weight 14
  @sensortype_voltage 15
  @sensortype_current 16
  @sensortype_co2 17
  @sensortype_airflow 18
  @sensortype_tankcapacity 19
  @sensortype_distance 20
  @sensortype_angleposition 21
  @sensortype_rotation 22
  @sensortype_watertemperature 23
  @sensortype_soiltemperature 24
  @sensortype_seismicintensity 25
  @sensortype_seismicmagnitude 26
  @sensortype_ultraviolet 27
  @sensortype_electricalresistivity 28
  @sensortype_electricalconductivity 29
  @sensortype_loudness 30
  @sensortype_moisture 31
  @sensortype_maxtype 32

  @size_mask    0x07
  @scale_mask   0x18
  @scale_shift  0x03
  @precision_mask 0xe0
  @precision_shift 0x05

  require Logger

  def start_link(_name, _node_id), do: nil

  def process_message(name, node_id, msg = <<@sof, _msgl, @request, @func_id_application_command_handler, _status, _node_id, _length, @command_class, _rest::binary>>) do
    private_process_message(name, node_id, msg)
  end
  def process_message(_, _, _), do: nil
  def private_process_message(name, node_id, <<@sof, _msglength, @request, @func_id_application_command_handler, _status, node_id, length, data::binary-size(length), _checksum>>) do
    parse_data(data) |> IO.inspect
    IO.inspect name
    IO.inspect node_id
  end

  def parse_data(<<@command_class, @sensormultilevelcmd_report, sensor_type, size_precision, value::binary>>) do
    use Bitwise
    size = size_precision &&& @size_mask
    scale = size_precision &&& @scale_mask >>> @scale_shift |> IO.inspect
    precision = size_precision &&& @precision_mask >>> @precision_shift
    size_bits = size * 8
    <<int_value::size(size_bits), _rest::binary>> = value

    IO.puts "Sensor: #{sensor_name(sensor_type)} | Value: #{int_value |> inspect} #{scale(sensor_type, scale)}"
  end

  def commands, do: []

  def add_command_class(state), do: state |> Map.put(:command_classes, [@command_class | state.command_classes])

  defp sensor_name(@sensortype_temperature), do: "Temperature"
  defp sensor_name(@sensortype_luminance), do: "Luminance"
  defp sensor_name(_), do: "Unknown"
  defp scale(@sensortype_temperature, 0), do: "C"
  defp scale(@sensortype_temperature, _), do: "F"
  defp scale(@sensortype_luminance, 0), do: "%"
  defp scale(@sensortype_luminance, _), do: "lux"
  defp scale(_, _), do: "Unknown"
end

# switch( sensorType )
# {
# 	case SensorType_Temperature:        units = scale ? "F" : "C";      break;
# 	case SensorType_General:        units = scale ? "" : "%";     break;
# 	case SensorType_Luminance:        units = scale ? "lux" : "%";      break;
# 	case SensorType_Power:          units = scale ? "BTU/h" : "W";      break;
# 	case SensorType_RelativeHumidity:     units = scale ? "" : "%";     break;
# 	case SensorType_Velocity:       units = scale ? "mph" : "m/s";      break;
# 	case SensorType_Direction:        units = "";         break;
# 	case SensorType_AtmosphericPressure:      units = scale ? "inHg" : "kPa";     break;
# 	case SensorType_BarometricPressure:     units = scale ? "inHg" : "kPa";     break;
# 	case SensorType_SolarRadiation:       units = "W/m2";         break;
# 	case SensorType_DewPoint:       units = scale ? "F" : "C";      break;
# 	case SensorType_RainRate:       units = scale ? "in/h" : "mm/h";    break;
# 	case SensorType_TideLevel:        units = scale ? "ft" : "m";     break;
# 	case SensorType_Weight:         units = scale ? "lb" : "kg";      break;
# 	case SensorType_Voltage:        units = scale ? "mV" : "V";     break;
# 	case SensorType_Current:        units = scale ? "mA" : "A";     break;
# 	case SensorType_CO2:          units = "ppm";          break;
# 	case SensorType_AirFlow:        units = scale ? "cfm" : "m3/h";     break;
# 	case SensorType_TankCapacity: {
# 	if (scale > 2) /* size of c_tankCapcityUnits minus invalid */
# 	{
# 	Log::Write (LogLevel_Warning, GetNodeId(), "Scale Value for c_tankCapcityUnits was greater than range. Setting to empty");
# 	units = c_tankCapcityUnits[3]; /* empty entry */
# 	}
# 	else
# 	{
# 	units = c_tankCapcityUnits[scale];
# 	}
# 	}
# 	break;
# 	case SensorType_Distance: {
# 	if (scale > 2) /* size of c_distanceUnits minus invalid */
# 	{
# 	Log::Write (LogLevel_Warning, GetNodeId(), "Scale Value for c_distanceUnits was greater than range. Setting to empty");
# 	units = c_distanceUnits[3]; /* empty entry */
# 	}
# 	else
# 	{
# 	units = c_distanceUnits[scale];
# 	}
# 	}
# 	break;
# 	case SensorType_AnglePosition: {
# 	if (scale > 2) /* size of c_anglePositionUnits minus invalid */
# 	{
# 	Log::Write (LogLevel_Warning, GetNodeId(), "Scale Value for c_anglePositionUnits was greater than range. Setting to empty");
# 	units = c_anglePositionUnits[3]; /* empty entry */
# 	}
# 	else
# 	{
# 	units = c_anglePositionUnits[scale];
# 	}
# 	}
# 	break;
# 	case SensorType_Rotation:       units = scale ? "hz" : "rpm";     break;
# 	case SensorType_WaterTemperature:     units = scale ? "F" : "C";      break;
# 	case SensorType_SoilTemperature:      units = scale ? "F" : "C";      break;
# 	case SensorType_SeismicIntensity: {
# 	if (scale > 3) /* size of c_seismicIntensityUnits minus invalid */
# 	{
# 	Log::Write (LogLevel_Warning, GetNodeId(), "Scale Value for c_seismicIntensityUnits was greater than range. Setting to empty");
# 	units = c_seismicIntensityUnits[4]; /* empty entry */
# 	}
# 	else
# 	{
# 	units = c_seismicIntensityUnits[scale];
# 	}
# 	}
# 	break;
#     case SensorType_SeismicMagnitude: {
#       if (scale > 3) /* size of c_seismicMagnitudeUnits minus invalid */
#       {
#         Log::Write (LogLevel_Warning, GetNodeId(), "Scale Value for c_seismicMagnitudeUnits was greater than range. Setting to empty");
#         units = c_seismicMagnitudeUnits[4]; /* empty entry */
#       }
#       else
#       {
#         units = c_seismicMagnitudeUnits[scale];
#       }
#     }
#     break;
#     case SensorType_Ultraviolet:        units = "";         break;
#     case SensorType_ElectricalResistivity:      units = "ohm";          break;
#     case SensorType_ElectricalConductivity:     units = "siemens/m";        break;
#     case SensorType_Loudness:       units = scale ? "dBA" : "db";     break;
#     case SensorType_Moisture: {
#       if (scale > 3) /* size of c_moistureUnits minus invalid */
#       {
#         Log::Write (LogLevel_Warning, GetNodeId(), "Scale Value for c_moistureUnits was greater than range. Setting to empty");
#         units = c_moistureUnits[4]; /* empty entry */
#       }
#       else
#       {
#         units = c_moistureUnits[scale];
#       }
#     }
#     break;
#     default: {
#       Log::Write (LogLevel_Warning, GetNodeId(), "sensorType Value was greater than range. Dropping");
#       return false;
#     }
#     break;

#   }

#   ValueDecimal* value = static_cast<ValueDecimal*>( GetValue( _instance, sensorType ) );
#   if( value == NULL)
#   {
#     node->CreateValueDecimal(  ValueID::ValueGenre_User, GetCommandClassId(), _instance, sensorType, c_sensorTypeNames[sensorType], units, true, false, "0.0", 0  );
#     value = static_cast<ValueDecimal*>( GetValue( _instance, sensorType ) );
#   }
#   else
#   {
#     value->SetUnits(units);
#   }

#   Log::Write( LogLevel_Info, GetNodeId(), "Received SensorMultiLevel report from node %d, instance %d, %s: value=%s%s", GetNodeId(), _instance, c_sensorTypeNames[sensorType],
# ) );
#   if( value->GetPrecision() != precision )
#   {
#     value->SetPrecision( precision );
#   }
#   value->OnValueRefreshed( valueStr );
#   value->Release();
#   return true;
# }
