defmodule Mg.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mingus,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: { Mg.App, [] },
      applications: [
	      :logger, :ranch
      ],
      env: []
    ]
  end

  defp deps do
    [
      {:ranch, "~> 1.3"},
      {:poolboy, "~> 1.5"}
    ]
  end
end
