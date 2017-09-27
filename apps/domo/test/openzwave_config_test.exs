defmodule OpenZWaveConfigTest do
  use ExUnit.Case

  test "can parse command classes from device_classes.xml" do
    assert OpenZWaveConfig.command_class(1, 2) |> Enum.sort == [0xef, 0x20, 0x2d, 0x72, 0x85, 0xef, 0x2b] |> Enum.sort
  end
end
