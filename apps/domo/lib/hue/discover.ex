defmodule Hue.Discover do
  use GenServer

  @discover_interval 30000

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

  @doc """
  do_discovery returns an array of tuples with form:
  {network_type, usb device, lambda to start ZStick}
  """
  def do_discovery do
    Huex.Discovery.discover
    |> Enum.map(fn ip_address -> {:hue_bridge, ip_address, fn() -> HueBridge.start(ip_address) end} end)
  end
end
