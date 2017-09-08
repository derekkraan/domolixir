defmodule ZStick.Resp do
  defstruct [:bytes]

  use ZStick.Constants

  def process(%ZStick.Resp{bytes: bytes}), do: process(bytes)
  def process(<<@ack, rest::binary>>) do
    IO.inspect("GOT ACK")
    process(rest)
  end
  def process(<<@sof, rest::binary>>) do
    rest
    |> extract_message
    |> interpret_message
  end
  def process(msg), do: :error

  defp extract_message(<<len, rest::binary>>) do
    len = len - 3
    require Logger
    Logger.debug("extracting #{len} elements from #{rest |> inspect}")
    <<message::binary-size(len), real_rest::binary>> = rest
    process_message(message)
    process(real_rest)
  end
  # defp extract_message(<<len, rest::binary>>) do
  #   len = len - 3
  #   <<message::binary-size(len), _::binary>> = rest
  #   message
  # end

  require Logger
  defp process_message(message) do
    message
    |> interpret_message
    |> Logger.debug
  end

  defp interpret_message(<<@response, @func_id_zw_get_version, version_string::binary>>), do: version_string
  defp interpret_message(<<@response, @func_id_zw_memory_get_id, rest::binary>>), do: {:zw_memory_get_id, rest}
  # defp interpret_message(<<@response, @func_id_zw_memory_get_id, home_id::binary-size(4), controller_node_id::binary-size(1)>>), do: {home_id, controller_node_id}
  defp interpret_message(msg), do: msg |> IO.inspect

  defp interpret_result(<<0x15>>), do: "NAK"
  defp interpret_result(<<0x06>>), do: "ACK"
  defp interpret_result(<<0x18>>), do: "CAN"
  defp interpret_result(res), do: res
end
