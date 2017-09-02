defmodule Fw.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    alias Nerves.Leds

    # Define workers and child supervisors to be supervised
    children = [
      # worker(Task, [fn ->
      #   :ok = Application.ensure_started :nerves_wpa_supplicant
      #   Nerves.Network.setup "wlan0", ssid: "The General", key_mgmt: :"WPA-PSK", psk: "EIDIZPLS"
      # end], restart: :transient)
    ]

    Leds.set connect: :slowblink

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fw.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
