defmodule Domo.EventListener.NetworkConnector do
  @moduledoc """
  This module tracks all network connect functions
  """

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    {:ok, %{}}
  end

  def connect(network_identifier, credentials) do
    GenServer.call(__MODULE__, {:connect, network_identifier, credentials})
  end

  def handle_call({:connect, network_identifier, credentials}, _from, connect_functions) do
    connect_functions |> IO.inspect()
    :ok = connect_functions[network_identifier][:connect].(credentials)
    {:reply, :ok, connect_functions}
  end

  def handle_call({:pair, network_identifier}, _from, connect_functions) do
    :ok = connect_functions["network_identifier"][:pair].()
    {:reply, :ok, connect_functions}
  end

  def handle_info(
        {:event,
         %{
           event_type: "network_discovered",
           network_identifier: network_identifier,
           connect: connect,
           pair: pair
         }},
        connect_functions
      ) do
    {:noreply,
     Map.merge(connect_functions, %{network_identifier => %{connect: connect, pair: pair}})}
  end

  def handle_info(event, connect_functions), do: {:noreply, connect_functions}
end
