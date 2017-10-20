defmodule BasicTest do
  use ExUnit.Case

  test "processes basic set with value 0 (off)" do
    msg = <<1, 9, 0, 4, 8, 19, 3, 32, 1, 0, 203>>
    assert %{node_id: 19, event_type: "basic_set", data: %{value: 0}} = ZWave.Basic.process_message("zwave", 19, msg)
  end

  test "processes basic set with value 255 (on)" do
    msg = <<1, 9, 0, 4, 8, 19, 3, 32, 1, 255, 52>>
    assert %{node_id: 19, event_type: "basic_set", data: %{value: 1}} = ZWave.Basic.process_message("zwave", 19, msg)
  end
end
