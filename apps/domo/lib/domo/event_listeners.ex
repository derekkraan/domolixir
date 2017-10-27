defmodule Domo.EventListeners do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, {}, name: __MODULE__)
  end

  def start_child(defn) do
    Supervisor.start_child(__MODULE__, defn)
  end

  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end
