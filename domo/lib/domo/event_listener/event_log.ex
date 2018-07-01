defmodule Domo.EventListener.EventLog do
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def empty_log do
    GenServer.call(__MODULE__, :empty_log)
  end

  def handle_info({:event, event}, log) do
    {:noreply, [event | log]}
  end

  def handle_call(:empty_log, _from, log) do
    {:reply, log, []}
  end
end
