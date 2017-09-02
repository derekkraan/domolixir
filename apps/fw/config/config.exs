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
#   rootfs_additions: "config/rootfs_additions",
#   fwup_conf: "config/fwup.conf"

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

config :web, Web.Endpoint,
  http: [port: 80],
  url: [host: "localhost", port: 80],
  secret_key_base: "PqJn6VoHDJkByj012wOBG8jt+p9GVRkhXvZpZfb9GdnAGy71G+ORBoOyluamRl/3",
  root: Path.dirname(__DIR__),
  server: true,
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Nerves.PubSub],
  code_reloader: false

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations
if Mix.Project.config[:target] != "" do
  import_config "#{(Mix.Project.config[:target] || "host")}.exs"
end

config :bootloader,
  init: [:nerves_runtime],
  app: :fw
