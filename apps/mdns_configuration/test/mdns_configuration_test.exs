defmodule MdnsConfigurationTest do
  use ExUnit.Case
  doctest MdnsConfiguration

  test "greets the world" do
    assert MdnsConfiguration.hello() == :world
  end
end
