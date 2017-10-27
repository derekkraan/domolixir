defmodule Domo.Listeners.SimpleResponder do
  use GenServer

  def start_link(name, pattern, command) do
    GenServer.start_link(__MODULE__, {pattern, command}, name: name)
  end

  def init({pattern, command}) do
    {:ok, %{pattern: pattern, command: command}}
  end

  def handle_info({:event, event}, %{pattern: pattern, command: command} = state) do
    if({pattern.event_type, pattern.node_id} == {event.event_type, event.node_id}) do
      apply(Kernel, :send, Tuple.to_list(command))
    end
    {:noreply, state}
  end
end
