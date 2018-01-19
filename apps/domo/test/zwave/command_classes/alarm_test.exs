defmodule ZWave.AlarmTest do
  use ExUnit.Case

  test "detects general alarm" do
    msg = <<1, 15, 0, 4, 0, 19, 9, 113, 5, 0, 0, 0, 255, 7, 3, 0, 97>>

    assert %{
             node_id: 19,
             event_type: "alarm",
             data: %{alarm_type: 0, alarm_type_name: "General", alarm_level: 0}
           } = ZWave.Alarm.process_message("zwave", 19, msg)
  end
end
