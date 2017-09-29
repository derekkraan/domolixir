defmodule ZWave.Msg do
  defstruct [:type, :function, :data, :callback_id, :target_node_id]

  use ZWave.Constants

  def prepare(msg = %ZWave.Msg{type: type, function: function, data: data, callback_id: callback_id}) do
    msg
    [@sof, 0x00, type, function]
    |> add_data(data)
    |> add_callback(callback_id)
    |> add_length()
    |> add_checksum()
    |> to_binary()
  end

  def prepare(msg), do: msg

  defp add_data(msg, nil), do: msg
  defp add_data(msg, data) do
    msg ++ data
  end

  defp add_callback(msg, nil), do: msg
  defp add_callback(msg, callback_id), do: msg ++ [callback_id]

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

  def required_response?(<<@nak>>, _resp), do: true

  # We don't get any node info back with this request,
  # so we have to assume that a response is talking
  # about the current command, so block until this is
  # received.
  def required_response?(%ZWave.Msg{function: @func_id_zw_get_node_protocol_info}, <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, _rest::binary>>), do: true
  def required_response?(%ZWave.Msg{function: @func_id_zw_get_node_protocol_info}, _resp), do: false

  def required_response?(%ZWave.Msg{function: @func_id_zw_set_learn_mode}, <<@ack>>), do: true
  def required_response?(%ZWave.Msg{function: function}, <<@sof, _length, @response, function, _rest::binary>>), do: true

  def required_response?(_req, <<@ack>>), do: true
  def required_response?(_req, <<@nak>>), do: true
  def required_response?(_req, <<@can>>), do: true
  def required_response?(_req, _resp), do: false
end
