use Mix.Config

config :mingus, id: "Mingus"

config :mingus, net: []

# Project-Fifo configuration:
config :libsniffle, sniffle: :mdns

# DNS
config :mingus,
  dns: [
    zones: []
  ]

config :erldns,
  catch_exceptions: false,
  use_root_hints: true,
  dnssec: [enabled: true],
  pools: [
    {:tcp_worker_pool, :erldns_worker, [size: 10, max_overflow: 20]}
  ]

# Data store
config :occi, model: Mg.Model
config :occi, backend: {OCCI.Backend.Agent, [priv_dir: "data.json"]}

import_config "#{Mix.env()}.exs"
