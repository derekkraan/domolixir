defmodule Domo.Manager do
  def discover do
    Supervisor.which_children(Domo.DiscoverSupervisor)
    |> Enum.flat_map(fn {discoverer, _pid, _worker, _def} -> discoverer.discover end)
  end

  def start(name) do
    fun = discover
          |> Enum.find(fn({network_type, network_name, fun}) -> network_name == name end)
          |> elem(2)
    fun.()
  end

  def all_nodes do
    Supervisor.which_children(Domo.SystemSupervisor)
    |> Enum.map(fn {name, _pid, _worker, _def} -> name end)
    |> Enum.flat_map(fn(name) ->
      Supervisor.which_children(name) |> Enum.map fn {name, _pid, _worker, _def} -> name end
    end)
  end

  def networks do
    Supervisor.which_children(Domo.SystemSupervisor) |> Enum.map fn {name, _pid, _worker, _def} -> name end
  end
end
