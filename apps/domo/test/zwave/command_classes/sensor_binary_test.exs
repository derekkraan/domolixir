defmodule SensorBinaryTest do
  use ExUnit.Case

  test "detects value 0" do
    msg = <<1, 9, 0, 4, 8, 19, 3, 48, 3, 0, 217>>

    assert %{node_id: 19, event_type: "sensor_binary", data: %{value: 0}} = ZWave.SensorBinary.process_message("zwave", 19, msg)
  end

  test "detects value 1" do
    msg = <<1, 9, 0, 4, 8, 19, 3, 48, 3, 255, 38>>

    assert %{node_id: 19, event_type: "sensor_binary", data: %{value: 1}} = ZWave.SensorBinary.process_message("zwave", 19, msg)
  end
end
