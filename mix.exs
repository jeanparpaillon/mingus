defmodule Mg.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mingus,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: [
        test: "test --no-start"
      ],

      # Docs
      name: "Mingus",
      source_url: "http://gitlab01.priv.cloud.kbrwadventure.com/kbrw/mingus",
      homepage_url: "http://gitlab01.priv.cloud.kbrwadventure.com/kbrw/mingus",
      docs: [
        #main: "Mg",
        logo: "priv/mingus_logo_only.png",
        extras: [ "_doc/manual.md", "_doc/devguide.md" ]
      ]
    ]
  end

  def application do
    [
      mod: { Mg.App, [] },
      registered: [
        :dns, :dns_tcp,
        Mg.Store,
        Mg.Providers.Ovh
      ],
      applications: [
	      :logger, :ranch,
        :crypto, :public_key, :ssl, :ssh, :uuid,
        :occi, :poolboy, :poison, :ex2ms, :retrieval
      ],
      env: []
    ]
  end

  defp deps do
    [
      {:occi, deps_occi(System.get_env("LOCAL_EXOCCI"))},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.15", only: :dev, runtime: false},
      {:ranch, "~> 1.3"},
      {:poolboy, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:ex2ms, "~> 1.5"},
      {:retrieval, github: "jeanparpaillon/retrieval"},
      {:distillery, "~> 1.4", runtime: true}
    ]
  end

  defp deps_occi(nil), do: [github: "erocci/exocci"]
  defp deps_occi(path), do: [path: path]
end
