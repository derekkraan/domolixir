defmodule Domo.EventGenerators do
  use Supervisor

  def start_link(children) do
    Supervisor.start_link(__MODULE__, children, name: __MODULE__)
  end

  def start_child(defn) do
    Supervisor.start_child(__MODULE__, defn)
  end

  def init(children) do
    supervise(children, strategy: :one_for_one)
  end
end
