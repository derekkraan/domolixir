defmodule EventBus do
  require Logger

  def send(event) do
    Logger.info "EVENT RECEIVED: #{event |> inspect}"

    process(event)

    # return the event to facilitate chaining
    event
  end

  def process(event) do
    Supervisor.which_children(Domo.EventListeners)
    |> Enum.each fn({_, listener, _, _}) -> send(listener, {:event, event}) end
  end
end
