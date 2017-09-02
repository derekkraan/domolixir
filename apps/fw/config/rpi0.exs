config :nerves_leds, names: [connect: "led0"]

config :nerves_network, regulatory_domain: "NL"

config :nerves_network, :default,
  wlan0: [
    ssid: "The General",
    psk: "EIDIZPLS",
    key_mgmt: :"WPA-PSK"
  ]
