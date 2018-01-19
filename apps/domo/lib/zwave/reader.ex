defmodule ZStick.Reader do
  use ZWave.Constants

  def start_link(usb_zstick_pid, zstick_pid) do
    reader_pid = spawn_link(fn -> ZStick.Reader.init(usb_zstick_pid, zstick_pid) end)
    {:ok, reader_pid}
  end

  def init(usb_zstick_pid, zstick_pid) do
    require Logger
    Logger.debug("INIT READER")
    read(usb_zstick_pid, zstick_pid)
  end

  # ms
  @read_wait 20

  def read(usb_zstick_pid, zstick_pid, msg_buffer \\ <<>>)

  def read(usb_zstick_pid, zstick_pid, msg_buffer) do
    {:ok, bytes} = ZStick.UART.read(usb_zstick_pid, @read_wait)

    {msg_buffer, messages} = process_bytes(bytes, msg_buffer)

    send_messages(messages |> Enum.reverse(), zstick_pid)

    read(usb_zstick_pid, zstick_pid, msg_buffer)
  end

  def send_messages([], _usb_zstick_pid), do: nil

  def send_messages([msg | rest], usb_zstick_pid) do
    GenServer.cast(usb_zstick_pid, {:message_from_zstick, msg})
    send_messages(rest, usb_zstick_pid)
  end

  def process_bytes(bytes, buff \\ <<>>, msgs \\ [])

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
    Logger.debug("SENDING :sendnak; byte: #{byte |> inspect}, buffer: #{buffer |> inspect}")
    # all other scenarios are unexpected so send NAK back to ZStick
    {<<>>, :sendnak}
  end

  def check_checksum(<<_sof, bytes::binary>>), do: check_checksum(bytes, 0xFF)

  def check_checksum(<<byte>>, checksum) do
    checksum == byte
  end

  def check_checksum(<<byte, rest::binary>>, checksum) do
    use Bitwise
    check_checksum(rest, checksum ^^^ byte)
  end
end
