defmodule ZWave.NodeBitmaskParser do
  def nodes_in_bytes(bytes, offset \\ 0, nodes \\ [])
  def nodes_in_bytes(<<>>, _offset, nodes), do: nodes

  def nodes_in_bytes(<<byte, bytes::binary>>, offset, nodes) do
    nodes_in_bytes(bytes, offset + 8, nodes_in_byte(byte, offset) ++ nodes)
  end

  def nodes_in_byte(byte, offset, counter \\ 0, nodes \\ [])
  def nodes_in_byte(_byte, _offset, 8, nodes), do: nodes

  def nodes_in_byte(byte, offset, counter, nodes) do
    use Bitwise

    if (byte &&& 1 <<< counter) != 0 do
      nodes_in_byte(byte, offset, counter + 1, [offset + counter + 1 | nodes])
    else
      nodes_in_byte(byte, offset, counter + 1, nodes)
    end
  end
end
