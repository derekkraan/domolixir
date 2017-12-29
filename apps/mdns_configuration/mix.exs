defmodule MdnsConfiguration.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mdns_configuration,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MdnsConfiguration.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mdns, "~> 0.1"},
    ]
  end
end
