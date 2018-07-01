defmodule EventBus do
  def send(event) do
    process(event)

    # return the event to facilitate chaining
    event
  end

  def process(event) do
    Supervisor.which_children(Domo.EventListeners)
    |> Enum.each(fn {_, listener, _, _} -> send(listener, {:event, event}) end)
  end
end
