defmodule ZStickTest do
  use ExUnit.Case

  test "can extract a message" do
    test_message = <<1, 16, 1, 21, 90, 45, 87, 97, 118, 101, 32, 51, 46, 57, 53, 0, 1, 153, 1, 16, 1, 21, 90, 45, 87, 97>>
    assert ZStick.Resp.process(test_message) == "Z-Wave 3.95"
  end
end
