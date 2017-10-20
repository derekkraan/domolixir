defmodule SensorAlarmTest do
  use ExUnit.Case

  test "detects a sensor alarm" do
    msg = <<1, 13, 0, 4, 8, 19, 7, 156, 2, 19, 0, 0, 0, 0, 103>>

    assert %{node_id: 19, event_type: "sensor_alarm", data: %{value: 0}} = ZWave.SensorAlarm.process_message("zwave", 19, msg)
  end

  # <<1, 13, 0, 4, 8, 19, 7, 156, 2, 19, 0, 0, 0, 0, 103>>
  # <<1, 13, 0, 4, 0, 19, 7, 156, 2, 19, 0, 0, 0, 0, 111>>
end
