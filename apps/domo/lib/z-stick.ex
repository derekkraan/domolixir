defmodule ZStick do
  use GenServer

  @sof 0x01
  @request 0x00
  @response 0x01

  @func_id_zw_get_version 0x15
  @func_id_zw_get_controller_capabilities 0x05
  @set_parameter 0xf2

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
    IO.inspect(pid)

    send(pid, @request, @func_id_zw_get_controller_capabilities)
    # write(pid, [0x15])
    # read(pid) |> IO.inspect
    # write(pid, add_checksum([0x01, 0x04, 0x51, 0x01, 0x01]) |> IO.inspect)

    out = read(pid)

    {:reply, out, pid}
  end

  defp send(pid, msgtype, function) do
    message = [@sof, 0x00, msgtype, function] |> add_checksum() |> add_length() |> IO.inspect
    write(pid, message)
  end

  defp write(pid, msg) do
    Nerves.UART.write(pid, msg)
  end

  defp read(pid), do: Nerves.UART.read(pid, 4000)

  defp add_checksum([sof | bytes]) do
    [sof | bytes] ++ [calc_checksum(bytes)]
  end

  defp add_length(bytes) do
    _length = (bytes |> length) - 2
    bytes |> List.update_at(1, fn(_) -> _length end)
  end

  defp calc_checksum(sum\\0xFF, _)
  defp calc_checksum(sum, []), do: sum
  defp calc_checksum(sum, [byte | bytes]) do
    use Bitwise
    calc_checksum(sum ^^^ byte, bytes)
  end
end
