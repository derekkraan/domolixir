defmodule Domo.EventListener.SimpleResponder do
  use GenServer

  def start_link(pattern, command) do
    GenServer.start_link(__MODULE__, {pattern, command})
  end

  def init({pattern, command}) do
    {:ok, %{pattern: pattern, command: command}}
  end

  def handle_info({:event, event}, %{pattern: pattern, command: command} = state) do
    if {pattern.event_type, pattern.node_id} == {event.event_type, event.node_id} do
      apply(Kernel, :send, Tuple.to_list(command))
    end

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
