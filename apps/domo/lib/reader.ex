defmodule ZStick.Reader do
  use ZStick.Constants

  def start_link(zstick_pid) do
    reader_pid = spawn_link fn -> ZStick.Reader.init(zstick_pid) end
    {:ok, reader_pid}
  end

  def init(zstick_pid) do
    require Logger
    Logger.debug "INIT READER"
    read(zstick_pid)
  end

  @read_wait 10 #ms

  def read(zstick_pid, msg_buffer\\<<>>)
  def read(zstick_pid, msg_buffer) do
    require Logger
    # Logger.debug "READING BYTES"
    {:ok, bytes} = ZStick.UART.read(zstick_pid, @read_wait)
    # Logger.debug "READ #{bytes}"
    {msg_buffer, messages} = process_bytes(bytes, msg_buffer)
    send_messages(messages |> Enum.reverse)
    read(zstick_pid, msg_buffer)
  end

  def send_messages([]), do: nil
  def send_messages([msg | rest]) do
    GenServer.cast(ZStick, {:message_from_zstick, msg})
    send_messages(rest)
  end

  def process_bytes(bytes, buff\\<<>>, msgs\\[])

  def process_bytes(<<>>, buff, msgs), do: {buff, msgs}

  def process_bytes(<<byte, bytes::binary>>, buff, msgs) do
    require Logger
    case process_byte(byte, buff) do
      {buff} -> process_bytes(bytes, buff, msgs)
      {buff, msg} -> process_bytes(bytes, buff, [msg | msgs])
    end
  end

  def process_byte(@sof, <<>>) do
    {<<@sof>>}
  end
  def process_byte(length, <<@sof>>) do
    {<<@sof, length>>}
  end
  def process_byte(byte, buff = <<@sof, length, bytes::binary>>) do
    if length == (bytes <> <<byte>>) |> byte_size() do
      msg = buff <> <<byte>>
      if check_checksum(msg) do
        {<<>>, buff <> <<byte>>}
      else
        {<<>>, :sendnak}
      end
    else
      {buff <> <<byte>>}
    end
  end

  def process_byte(@nak, <<>>), do: {<<>>, <<@nak>>}
  def process_byte(@ack, <<>>), do: {<<>>, <<@ack>>}
  def process_byte(@can, <<>>), do: {<<>>, <<@can>>}
  def process_byte(<<>>, <<>>), do: {<<>>}
  def process_byte(byte, buffer) do
    require Logger
    Logger.debug "SENDING :sendnak; byte: #{byte |> inspect}, buffer: #{buffer |> inspect}"
    {<<>>, :sendnak} # all other scenarios are unexpected so send NAK back to ZStick
  end

  def check_checksum(<<_sof, bytes::binary>>), do: check_checksum(bytes, 0xff)
  def check_checksum(<<byte>>, checksum) do
    IO.inspect("checksum: #{checksum |> inspect}, byte: #{byte |> inspect}")
    checksum == byte
  end
  def check_checksum(<<byte, rest::binary>>, checksum) do
    use Bitwise
    check_checksum(rest, checksum ^^^ byte)
  end
end
