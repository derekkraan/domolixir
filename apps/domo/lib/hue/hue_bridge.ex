defmodule HueBridge do
  use GenServer

  def start_link(ip, username) do
    GenServer.start_link(__MODULE__, {ip, username}, name: __MODULE__)
  end

  def init({ip, username}) do
    {:ok, Huex.connect(ip, username)}
  end

  def handle_info({:turn_on, light_id}, bridge) do
    Huex.turn_on(bridge, light_id)
    {:noreply, bridge}
  end

  def handle_info({:turn_off, light_id}, bridge) do
    Huex.turn_off(bridge, light_id)
    {:noreply, bridge}
  end
end
