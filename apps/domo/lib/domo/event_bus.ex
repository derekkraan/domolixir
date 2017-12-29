defmodule EventBus do
  def send(event) do
    process(event)

    event # return the event to facilitate chaining
  end

  def process(event) do
    Supervisor.which_children(Domo.EventListeners)
    |> Enum.each fn({_, listener, _, _}) -> send(listener, {:event, event}) end
  end
end
