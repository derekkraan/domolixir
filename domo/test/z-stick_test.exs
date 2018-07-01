defmodule ZStickTest do
  use ExUnit.Case

  test "can extract a message" do
    test_message =
      <<1, 16, 1, 21, 90, 45, 87, 97, 118, 101, 32, 51, 46, 57, 53, 0, 1, 153, 1, 16, 1, 21, 90,
        45, 87, 97>>

    {buff, msgs} = ZStick.Reader.process_bytes(test_message)
    msg = msgs |> List.first()
    <<sof, length, response, function_type, msg_and_checksum::binary>> = msg
    rom_size = (msg_and_checksum |> byte_size()) - 3
    # rom_size = length - 5
    <<msg::binary-size(rom_size), checksum::binary>> = msg_and_checksum
    assert "Z-Wave 3.95" == msg
  end
end
