defmodule EventBus do
  require Logger

  def send(event) do
    Logger.info "EVENT RECEIVED: #{event |> inspect}"

    event # return the event
  end
end
