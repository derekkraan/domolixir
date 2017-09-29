defmodule ZWave.Discover do
  use GenServer

  @discover_interval 5000

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def discover do
    GenServer.call(__MODULE__, :get_discovered)
  end

  def handle_call(:get_discovered, _from, state), do: {:reply, state.discovered, state}

  def init(_) do
    Process.send_after(self(), :discover, @discover_interval)
    {:ok, %{discovered: do_discovery}}
  end

  def handle_info(:discover, state) do
    Process.send_after(self(), :discover, @discover_interval)
    {:noreply, %{state | discovered: do_discovery}}
  end

  def do_discovery do
    Nerves.UART.enumerate
    |> Enum.filter(&filter/1)
    |> Enum.map(fn({usb_dev, _info}) ->
      {usb_dev, fn() -> ZWave.ZStick.start(usb_dev, usb_dev |> String.to_atom) end}
    end)
  end

  def filter({usb_dev, %{product_id: 512, vendor_id: 1624}}), do: usb_dev
  def filter(_), do: nil
end
