defmodule Domo.EventListener.Nodes do
  @moduledoc """
  This module tracks all nodes and their properties.
  """

  defmodule Node, do: defstruct [:network_identifier, :node_identifier, :alive, :commands, :on_off_status]

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    {:ok, %{}}
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  def handle_call(:get, _from, networks) do
    {:reply, networks, networks}
  end

  def handle_info({:event, %{event_type: "node_on", node_identifier: node_identifier} = event}, nodes) do
    if Map.has_key?(nodes, node_identifier) do
      updated_node = nodes[node_identifier] |> Map.merge(%{on_off_status: "on"})
      {:noreply, nodes |> Map.merge(%{node_identifier => updated_node})}
    else
      {:noreply, nodes}
    end
  end

  def handle_info({:event, %{event_type: "node_off", node_identifier: node_identifier} = event}, nodes) do
    if Map.has_key?(nodes, node_identifier) do
      updated_node = nodes[node_identifier] |> Map.merge(%{on_off_status: "off"})
      {:noreply, nodes |> Map.merge(%{node_identifier => updated_node})}
    else
      {:noreply, nodes}
    end
  end

  def handle_info({:event, %{event_type: "node_alive", node_identifier: node_identifier, alive: alive} = event}, nodes) do
    if Map.has_key?(nodes, node_identifier) do
      updated_node = nodes[node_identifier] |> Map.merge(%{alive: alive})
      {:noreply, nodes |> Map.merge(%{node_identifier => updated_node})}
    else
      {:noreply, nodes}
    end
  end

  def handle_info({:event, %{event_type: "node_added", network_identifier: network_identifier, node_identifier: node_identifier} = event}, nodes) do
    if Map.has_key?(nodes, node_identifier) do
      # node already added
      {:noreply, nodes}
    else
      # add node
      new_node = struct(Node, event)
      {:noreply, nodes |> Map.merge(%{node_identifier => new_node})}
    end
  end

  def handle_info({:event, %{event_type: "node_has_commands", commands: commands, node_identifier: node_identifier} = event}, nodes) do
    if Map.has_key?(nodes, node_identifier) do
      updated_node = nodes[node_identifier] |> Map.merge(%{commands: commands})
      {:noreply, nodes |> Map.merge(%{node_identifier => updated_node})}
    else
      {:noreply, nodes}
    end
  end

  def handle_info(_, networks), do: {:noreply, networks}
end
