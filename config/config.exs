use Mix.Config

config :mingus, id: "Mingus"

config :mingus, net: []

# DNS
config :erldns, catch_exceptions: false
config :erldns, use_root_hints: true
config :erldns, dnssec: [enabled: true]

config :erldns,
  zone_delegates: [
    {"cloud.example.com", Mg.DNS.Fifo}
  ]

config :erldns,
  pools: [
    {:tcp_worker_pool, :erldns_worker,
     [
       size: 10,
       max_overflow: 20
     ]}
  ]

# Data store
config :occi, model: Mg.Model
config :occi, backend: {OCCI.Backend.Agent, [priv_dir: "data.json"]}

import_config "#{Mix.env()}.exs"
