use Mix.Config

config :web, Web.Endpoint,
  http: [port: 3001],
  url: [host: "localhost", port: 3001],
  secret_key_base: "PqJn6VoHDJkByj012wOBG8jt+p9GVRkhXvZpZfb9GdnAGy71G+ORBoOyluamRl/3",
  root: Path.dirname(__DIR__),
  server: true,
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Nerves.PubSub],
  code_reloader: false
