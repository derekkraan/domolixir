defmodule Domo.EventListener.Networks do
  @moduledoc """
  This module tracks all networks (eg, Hue, ZWave, etc) and their properties.
  """

  defmodule Network, do: defstruct [:network_type, :network_identifier, :paired, :connected]

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

  def handle_info({:event, %{event_type: "network_discovered", network_identifier: network_identifier} = event}, networks) do
    if Map.has_key?(networks, network_identifier) do
      # network already added
      {:noreply, networks}
    else
      # add network
      network = struct(Network, event)
      {:noreply, networks |> Map.merge(%{network_identifier => network})}
    end
  end

  def handle_info(_, networks), do: {:noreply, networks}
end
