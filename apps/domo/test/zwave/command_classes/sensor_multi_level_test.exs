defmodule SensorMultiLevelTest do
  use ExUnit.Case

  test "can extract temperature" do
    msg = <<1, 12, 0, 4, 0, 19, 6, 49, 5, 1, 34, 0, 255, 10>>
    assert %{node_id: 19, event_type: "sensor_multi_level", data: %{sensor_name: "Temperature", value: 25.5, unit: "C"}} = ZWave.SensorMultiLevel.process_message("zwave", 19, msg)
  end

  test "can extract luminance" do
    msg = <<1, 12, 0, 4, 0, 19, 6, 49, 5, 3, 10, 1, 33, 255>>
    assert %{node_id: 19, event_type: "sensor_multi_level", data: %{sensor_name: "Luminance", value: 289.0, unit: "lux"}} = ZWave.SensorMultiLevel.process_message("zwave", 19, msg)
  end
end
