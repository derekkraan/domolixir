defmodule Domo.EventGenerator.Clock do
  use GenServer

  # ms
  @tick_interval 10000

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    send_tick()
    {:ok, nil}
  end

  def handle_info(:tick, state) do
    send_tick()
    %{event_type: "clock_update", node_id: nil, datetime: Timex.now()} |> EventBus.send()
    {:noreply, state}
  end

  defp send_tick, do: Process.send_after(self(), :tick, @tick_interval, [])
end
