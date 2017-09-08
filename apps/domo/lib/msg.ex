defmodule ZStick.Msg do
  defstruct [:type, :function, :data]

  use ZStick.Constants

  def prepare(msg = %ZStick.Msg{type: type, function: function, data: data}) do
    msg
    [@sof, 0x00, type, function] ++ (data || [])
    |> add_length()
    |> add_checksum()
    |> to_binary()
  end

  def prepare(msg), do: msg

  defp add_checksum(msg = [sof | bytes]) do
    msg ++ [calc_checksum(bytes)]
  end

  # should be OK (for different lengths we get NOTHING back)
  defp add_length(bytes) do
    _length = (bytes |> length) - 1
    bytes |> List.update_at(1, fn(_) -> _length end)
  end

  defp to_binary(bytes, binary\\<<>>)
  defp to_binary([], binary), do: binary
  defp to_binary([byte | bytes], binary) do
    to_binary(bytes, binary <> <<byte>>)
  end

  defp calc_checksum(sum\\0xFF, _)
  defp calc_checksum(sum, []), do: sum
  defp calc_checksum(sum, [byte | bytes]) do
    use Bitwise
    calc_checksum(sum ^^^ byte, bytes)
  end

  def required_response?(<<@nak>>, _), do: true
  def required_response?(%ZStick.Msg{function: @func_id_zw_set_learn_mode}, <<@ack>>), do: true
  def required_response?(%ZStick.Msg{function: function}, <<@sof, _length, @request, function, _rest::binary>>), do: true

  def required_response?(_, <<@ack>>), do: true
  def required_response?(_, <<@nak>>), do: true
  def required_response?(_, <<@can>>), do: true
  def required_response?(_, _), do: false
end
