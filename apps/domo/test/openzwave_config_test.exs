defmodule OpenZWaveConfigTest do
  use ExUnit.Case

  test "can parse command classes from device_classes.xml" do
    assert OpenZWaveConfig.command_classes(1, 2) |> Enum.sort() ==
             [0xEF, 0x20, 0x2D, 0x72, 0x85, 0xEF, 0x2B] |> Enum.sort()

    assert OpenZWaveConfig.command_classes(17, 1) |> Enum.sort() ==
             [0x20, 0x26, 0x27] |> Enum.sort()
  end

  test "returns empty list when nothing is found" do
    assert OpenZWaveConfig.command_classes(100, 100) == []
  end
end
