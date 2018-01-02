defmodule Hue.Discover do
  use GenServer

  @discover_interval 5000

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :discover, @discover_interval)
    {:ok, nil}
  end

  def handle_info(:discover, _state) do
    Process.send_after(self(), :discover, @discover_interval)
    do_discovery()
    {:noreply, nil}
  end

  @doc """
  do_discovery returns an array of tuples with form:
  {network_type, usb device, lambda to start ZStick}
  """
  def do_discovery do
    Huex.Discovery.discover |> Enum.each(fn ip_address ->
      %{
        event_type: "network_discovered",
        network_type: :hue_bridge,
        network_identifier: ip_address,
        pair: pair(ip_address),
        connect: connect(ip_address),
      } |> EventBus.send()
    end)
  end

  defp pair(ip_address), do: fn() -> HueBridge.start(ip_address) end
  defp connect(ip_address), do: fn(username) -> HueBridge.start(ip_address, username) end
end
