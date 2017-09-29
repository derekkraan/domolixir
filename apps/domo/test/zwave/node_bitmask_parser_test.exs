defmodule ZWave.NodeBitmaskParserTest do
  use ExUnit.Case

  test "extracts the correct node ids" do
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<1698581952322158864250719868509920402871458993715456615420781756678144::size(232)>>) == [9, 6, 5, 4, 3, 2, 1]

    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<255>>) == [8, 7, 6, 5, 4, 3, 2, 1]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<0, 1>>) == [9]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<0, 0, 1>>) == [17]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<128, 0, 0>>) == [8]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<0, 128, 0, 0>>) == [16]
  end
end
