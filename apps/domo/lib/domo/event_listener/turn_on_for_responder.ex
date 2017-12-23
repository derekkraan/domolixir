defmodule Domo.EventListener.TurnOnForResponder do
  use GenServer

  def start_link(pattern, turn_on_command, turn_off_command, how_long) do
    GenServer.start_link(__MODULE__, {pattern, turn_on_command, turn_off_command, how_long})
  end

  def init({pattern, turn_on_command, turn_off_command, how_long}) do
    {:ok, %{pattern: pattern, turn_on_command: turn_on_command, turn_off_command: turn_off_command, how_long: how_long, counter: 0}}
  end

  def handle_info({:event, event}, state = %{pattern: pattern, turn_on_command: turn_on_command, how_long: how_long}) do
    if({pattern.event_type, pattern.node_id} == {event.event_type, event.node_id}) do
      apply(Kernel, :send, Tuple.to_list(turn_on_command))
      Process.send_after(self(), {:turn_off, state.counter + 1}, how_long)
      {:noreply, %{state | counter: state.counter + 1}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:turn_off, counter}, state = %{counter: counter, turn_off_command: turn_off_command}) do
    apply(Kernel, :send, Tuple.to_list(turn_off_command))
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
