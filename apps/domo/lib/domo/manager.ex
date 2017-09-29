defmodule Domo.Manager do
  @networks [ZStick]

  def discover do
    @networks
    |> Enum.flat_map(fn(network) -> Module.concat(network, Discover).discover end)
  end

  def start(name) do
    fun = discover
          |> Enum.find(fn({network, fun}) -> network == name end)
          |> elem(1)
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
