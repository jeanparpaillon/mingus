defmodule Mg.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mingus,
      version: "0.1.0",
      elixir: ">= 1.3.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(Mix.env()),
      dialyzer: [plt_add_deps: :project],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env_for(:test, ~w(
            coveralls coveralls.detail coverall.html coveralls.json coveralls.post
          )),

      # Docs
      name: "Mingus",
      source_url: "http://github.com/kbrw/mingus",
      homepage_url: "http://github.com/kbrw/mingus",
      docs: [
        # main: "Mg",
        logo: "priv/mingus_logo_only.png",
        extras: ["_doc/manual.md", "_doc/devguide.md"]
      ]
    ]
  end

  def application do
    [
      mod: {Mg, []},
      registered: [
        :dns,
        :dns_tcp,
        Mg.Store,
        Mg.Providers.Ovh
      ],
      extra_applications: [
        :logger,
        :inets,
        :crypto,
        :public_key,
        :ssl,
        :ssh,
        :uuid
      ],
      env: []
    ]
  end

  defp aliases(:prod), do: []
  defp aliases(_) do
    [
      compile: ["format", "compile", "credo"],
      test: "test --no-start"
    ]
  end

  defp deps do
    [
      # Dev and test
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev, :test], runtime: false},
      # Dev only
      {:earmark, "~> 1.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.15", only: :dev, runtime: false},
      # Test only
      {:excoveralls, "~> 0.9", only: :test, runtime: false},
      # All envs
      {:occi, github: "erocci/exocci"},
      {:ranch, "~> 1.3"},
      {:poolboy, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:ex2ms, "~> 1.5"},
      {:retrieval, github: "jeanparpaillon/retrieval"},
      {:distillery, "~> 1.4", runtime: false},
      {:edeliver, "~> 1.4", runtime: false}
    ]
  end

  defp cli_env_for(env, tasks) do
    tasks
    |> Enum.reduce([], &Keyword.put(&2, :"#{&1}", env))
  end
end
