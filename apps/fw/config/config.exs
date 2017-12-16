# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Customize the firmware. Uncomment all or parts of the following
# to add files to the root filesystem or modify the firmware
# archive.

# config :nerves, :firmware,
#   rootfs_overlay: "rootfs_overlay",
#   fwup_conf: "config/fwup.conf"

# Use bootloader to start the main application. See the bootloader
# docs for separating out critical OTP applications such as those
# involved with firmware updates.
config :bootloader,
  init: [:nerves_runtime],
  app: Mix.Project.config[:app]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.Project.config[:target]}.exs"
config :nerves_firmware_ssh,
  authorized_keys: [
    File.read!(Path.join(System.user_home!, ".ssh/id_rsa.pub"))
  ]

config :nerves_network, :default,
  wlan0: [
    ssid: "The General",
    psk: "EIDIZPLS",
    key_mgmt: :"WPA-PSK"
  ]

config :web, Web.Endpoint,
  http: [port: 80],
  url: [host: "localhost", port: 80],
  secret_key_base: "PqJn6VoHDJkByj012wOBG8jt+p9GVRkhXvZpZfb9GdnAGy71G+ORBoOyluamRl/3",
  root: Path.dirname(__DIR__),
  server: true,
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Nerves.PubSub],
  code_reloader: false

config :ex_sshd,
  app: Mix.Project.config[:app],
  port: 10022,
  credentials: [{"derek", "secretly"}]
