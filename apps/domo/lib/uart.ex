defmodule ZStick.UART do
  def connect(location) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, location, speed: 115200, active: false)
    {:ok, pid}
  end

  def read(pid, timeout\\1000), do: Nerves.UART.read(pid, timeout)

  def write(msg, pid), do: Nerves.UART.write(pid, msg)
end
