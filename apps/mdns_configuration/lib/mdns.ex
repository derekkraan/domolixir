defmodule MdnsConfiguration.Mdns do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, configuration())
  end

  defp configuration do
    default_config = %{ifname: "wlan0", mdns_domain: "home.local"}
    provided_config = Application.get_all_env(:mdns_configuration) |> Enum.into(%{})
    config = Map.merge(default_config, provided_config)
    Logger.debug("MdnsConfiguration using config #{inspect(config)}")
    config
  end

  def init(opts) do
    SystemRegistry.register()

    init_mdns(opts[:mdns_domain])

    {:ok, %{ip: nil, ifname: opts[:ifname], opts: opts}}
  end

  def init_mdns(mdns_domain) do
    Mdns.Server.add_service(%Mdns.Server.Service{
      domain: mdns_domain,
      data: :ip,
      ttl: 120,
      type: :a
    })
  end

  def handle_info({:system_registry, :global, registry}, state) do
    new_ip = get_in(registry, [:state, :network_interface, state.ifname, :ipv4_address])
    handle_ip_update(state, new_ip)
  end

  defp handle_ip_update(%{ip: old_ip} = state, new_ip) when old_ip == new_ip do
    # no change
    {:noreply, state}
  end

  defp handle_ip_update(state, new_ip) do
    Logger.debug("IP address for #{state.ifname} changed to #{new_ip}")
    update_mdns(new_ip, state.opts[:mdns_domain])
    {:noreply, %{state | ip: new_ip}}
  end

  defp update_mdns(_ip, nil), do: :ok

  defp update_mdns(ip, _mdns_domain) do
    ip_tuple = to_ip_tuple(ip)
    Mdns.Server.stop()

    # Give the interface time to settle to fix an issue where mDNS's multicast
    # membership is not registered. This occurs on wireless interfaces and
    # needs to be revisited.
    :timer.sleep(100)

    Mdns.Server.start(interface: ip_tuple)
    Mdns.Server.set_ip(ip_tuple)
  end

  defp to_ip_tuple(str) do
    str
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end
end
