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
end

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

defmodule ZStick do
  use GenServer

  use ZStick.Constants

  defmodule State, do: defstruct [:zstick_pid, :command_queue, :waiting_for_ack]

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def message_from_zstick(message) do
    GenServer.cast(__MODULE__, :message_from_zstick, message)
  end

  def test, do: GenServer.call(__MODULE__, :test, 10000)
  def read, do: GenServer.call(__MODULE__, :read, 10000)

  def init(state) do
    {:ok, zstick_pid} = ZStick.UART.connect
    {:ok, reader_pid} = ZStick.Reader.start_link(zstick_pid)
    do_init_sequence(zstick_pid)
    {:ok, %State{zstick_pid: zstick_pid, command_queue: [], waiting_for_ack: false}}
  end

  def handle_call(:test, _ref, pid) do
    do_init_sequence(pid)
    %ZStick.Msg{type: @request, function: @func_id_zw_set_learn_mode} |> send_msg(pid)
    {:noreply, pid}
  end

  def handle_call(:read, _ref, pid) do
    # read(pid)
    # |> ZStick.Logger.log
    # |> ZStick.Resp.process
    # |> IO.inspect
    {:noreply, pid}
  end

  def handle_cast({:message_from_zstick, :sendnak}, pid) do
    require Logger
    Logger.debug "RECEIVED #{:sendnak} |> sending NAK"
    <<@nak>> |> send_msg(pid)
    {:noreply, pid}
  end
  def handle_cast({:message_from_zstick, message}, pid) do
    require Logger
    Logger.debug "RECEIVED #{message}"
    {:noreply, pid}
  end

  def do_init_sequence(pid) do
    <<@nak>> |> send_msg(pid)

    %ZStick.Msg{type: @request, function: @func_id_zw_get_version} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_zw_memory_get_id} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_zw_get_controller_capabilities} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_serial_api_get_capabilities} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_zw_get_suc_node_id} |> send_msg(pid)
  end

  defp send_msg(msg, pid) do
    msg
    |> ZStick.Logger.log
    |> ZStick.Msg.prepare
    |> write(pid)

    # read(pid)
    # |> ZStick.Logger.log
    # |> ZStick.Resp.process
    # |> IO.inspect
  end

  defp write(msg, pid) do
    Nerves.UART.write(pid, msg)
  end

  defp read(pid, out\\"") do
    # case Nerves.UART.read(pid, 50) do
    #   {:ok, ""} -> %ZStick.Resp{bytes: out}
    #   {:ok, just_read} -> read(pid, out <> just_read)
    # end
  end
end

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

  def read(zstick_pid, msg_buffer\\<<>>)
  def read(zstick_pid, msg_buffer) do
    require Logger
    # Logger.debug "READING BYTES"
    {:ok, bytes} = ZStick.UART.read(zstick_pid)
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

  def process_bytes(<<byte::binary-size(1), bytes::binary>>, buff, msgs) do
    require Logger
    case process_byte(byte, buff) do
      {buff, nil} -> process_bytes(bytes, buff, msgs)
      {buff, msg} -> process_bytes(bytes, buff, [msg | msgs])
    end
  end

  def process_byte(<<@sof>>, <<>>) do
    {<<@sof>>, nil}
  end
  def process_byte(<<length>>, <<@sof>>) do
    {<<@sof, length>>, nil}
  end
  def process_byte(byte, buff = <<@sof, length, bytes::binary>>) do
    if length == (bytes <> byte) |> byte_size() do
      msg = buff <> byte
      if check_checksum(msg) do
        {<<>>, buff <> byte}
      else
        {<<>>, :sendnak}
      end
    else
      {buff <> byte, nil}
    end
  end

  def process_byte(<<@nak>>, <<>>), do: {<<>>, <<@nak>>}
  def process_byte(<<@ack>>, <<>>), do: {<<>>, <<@ack>>}
  def process_byte(<<>>, <<>>), do: {<<>>, nil}
  def process_byte(_, _), do: {<<>>, :sendnak} # all other scenarios are unexpected so send NAK back to ZStick

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
