defmodule ZWave.Discover do
  use GenServer

  @discover_interval 5000

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :discover, @discover_interval)
    {:ok, nil}
  end

  def handle_info(:discover, state) do
    Process.send_after(self(), :discover, @discover_interval)
    do_discovery()
    {:noreply, nil}
  end

  @doc """
  do_discovery returns an array of tuples with form:
  {network_type, usb device, lambda to start ZStick}
  """
  def do_discovery do
    Nerves.UART.enumerate()
    |> Enum.filter(&filter/1)
    |> Enum.each(fn {usb_dev, _info} ->
      %{
        event_type: "network_discovered",
        network_identifier: usb_dev,
        network_type: :zwave_zstick,
        paired: true,
        connected: false,
        pair: pair(usb_dev),
        connect: connect(usb_dev)
      }
      |> EventBus.send()
    end)
  end

  defp pair(usb_dev), do: nil

  defp connect(usb_dev),
    do: fn _credentials -> ZWave.ZStick.start(usb_dev, usb_dev |> String.to_atom()) end

  defp filter({usb_dev, %{product_id: 512, vendor_id: 1624}}), do: usb_dev
  defp filter(_), do: nil
end
