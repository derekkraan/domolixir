defprotocol ZStick.Logger do
  @fallback_to_any true
  def log(data)
end

defimpl ZStick.Logger, for: ZStick.Msg do
  require Logger
  def log(msg) do
    "Sending message: #{msg |> inspect}" |> Logger.debug
    msg
  end
end

defimpl ZStick.Logger, for: ZStick.Resp do
  require Logger
  def log(resp) do
    "Received: #{resp.bytes |> inspect}" |> Logger.debug
    resp
  end
end

defimpl ZStick.Logger, for: Any do
  require Logger
  def log(any) do
    Logger.debug(any)
    any
  end
end

defmodule ZStick.Constants do
  defmacro __using__(_) do
    quote do
      @func_id_zw_get_version 0x15
      @func_id_zw_memory_get_id 0x20
      @func_id_zw_get_controller_capabilities 0x05
      @func_id_serial_api_get_capabilities 0x07
      @func_id_zw_get_suc_node_id 0x56

      @func_id_zw_get_random 0x1c
      @func_id_zw_get_controller_capabilities 0x05

      @request 0x00
      @response 0x01

      @sof 0x01
      @ack 0x06
      @nak 0x15
      @can 0x18
    end
  end
end

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
  def process(<<1, rest::binary>>) do
    rest
    |> extract_message
    |> interpret_message
  end
  def process(msg), do: :error

  defp extract_message(<<len, rest::binary>>) do
    len = len - 3
    <<message::binary-size(len), _::binary>> = rest
    message
  end

  defp interpret_message(<<@response, @func_id_zw_get_version, version_string::binary>>), do: version_string
  defp interpret_message(msg), do: msg |> IO.inspect

  defp interpret_result(<<0x15>>), do: "NAK"
  defp interpret_result(<<0x06>>), do: "ACK"
  defp interpret_result(<<0x18>>), do: "CAN"
  defp interpret_result(res), do: res
end

defmodule ZStick do
  use GenServer

  use ZStick.Constants

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def hello, do: GenServer.call(__MODULE__, :hello, 10000)

  def init(state) do
    {:ok, pid} = Nerves.UART.start_link
    Nerves.UART.open(pid, "/dev/cu.usbmodem1411", speed: 115200, active: false)
    {:ok, pid}
  end

  def handle_call(:hello, _ref, pid) do
    <<@nak>> |> send_msg(pid)

    %ZStick.Msg{type: @request, function: @func_id_zw_get_version} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_zw_memory_get_id} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_zw_get_controller_capabilities} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_serial_api_get_capabilities} |> send_msg(pid)
    %ZStick.Msg{type: @request, function: @func_id_zw_get_suc_node_id} |> send_msg(pid)

    {:reply, nil, pid}
  end

  defp send_msg(msg, pid) do
    msg
    |> ZStick.Logger.log
    |> ZStick.Msg.prepare
    |> write(pid)

    read(pid)
    |> ZStick.Logger.log
    |> ZStick.Resp.process
    |> IO.inspect
  end

  defp write(msg, pid) do
    Nerves.UART.write(pid, msg)
  end

  defp read(pid) do
    {:ok, out} = Nerves.UART.read(pid, 100)
    {:ok, out2} = Nerves.UART.read(pid, 100)
    {:ok, out3} = Nerves.UART.read(pid, 100)
    {:ok, out4} = Nerves.UART.read(pid, 100)
    %ZStick.Resp{bytes: out <> out2 <> out3 <> out4}
  end
end
