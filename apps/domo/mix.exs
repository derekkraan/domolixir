defmodule Domo.Mixfile do
  use Mix.Project

  def project do
    [app: :domo,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:sasl, :logger, :huex, :nerves_ssdp_client, :nerves_uart, :timex],
     mod: {Domo.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:huex, "~> 0.6"},
      {:httpotion, "~> 3.0"},
      {:nerves_ssdp_client, "~> 0.1.0"},
      {:nerves_uart, "~> 1.0"},
      {:benchfella, "~> 0.3.0"},
      {:timex, "~> 3.1"},
    ]
  end
end
