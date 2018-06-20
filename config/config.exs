use Mix.Config

config :mingus, id: "Mingus"

config :mingus,
  dns: [
    nameservers: [
      {{8, 8, 8, 8}, 53}
    ]
  ]

config :mingus, net: []

config :occi, model: Mg.Model
config :occi, backend: {OCCI.Backend.Agent, [priv_dir: "data.json"]}

import_config "#{Mix.env()}.exs"
