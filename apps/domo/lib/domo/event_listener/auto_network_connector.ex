defmodule Domo.EventListener.AutoNetworkConnector do
  use GenServer

  def start_link(network_identifier, credentials) do
    GenServer.start_link(__MODULE__, {network_identifier, credentials})
  end

  def init({network_identifier, credentials}) do
    {:ok, %{network_identifier: network_identifier, credentials: credentials}}
  end

  def handle_info(
        {:event,
         %{
           event_type: "network_discovered",
           network_identifier: network_identifier,
           connect: connect
         }},
        state = %{network_identifier: network_identifier, credentials: credentials}
      ) do
    connect.(credentials)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
