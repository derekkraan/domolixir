defmodule ZWave.NodeBitmaskParserTest do
  use ExUnit.Case

  test "extracts the correct node ids" do
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(
             <<1_698_581_952_322_158_864_250_719_868_509_920_402_871_458_993_715_456_615_420_781_756_678_144::size(
                 232
               )>>
           ) == [9, 6, 5, 4, 3, 2, 1]

    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<255>>) == [8, 7, 6, 5, 4, 3, 2, 1]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<0, 1>>) == [9]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<0, 0, 1>>) == [17]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<128, 0, 0>>) == [8]
    assert ZWave.NodeBitmaskParser.nodes_in_bytes(<<0, 128, 0, 0>>) == [16]
  end
end
