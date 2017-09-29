defmodule Domo.Node do
  def get_information(node), do: GenServer.call(node, :get_information)
  def get_commands(node), do: GenServer.call(node, :get_commands)
end
