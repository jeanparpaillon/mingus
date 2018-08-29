use Mix.Config

config :mingus, id: "Mingus"

config :mingus, net: []

# Project-Fifo configuration:
# [ fifo_service() ]
# fifo_service :: {fifo_name(), mdns | {ip :: charlist(), port :: integer()}}
# fifo_name :: sniffle
config :mingus,
  fifo_services: [
    sniffle: :mdns
  ]

# DNS
config :mingus,
  dns: [
    servers: [{"0.0.0.0", 53, processes: 2}],
    pool: [
      size: 10,
      max_overflow: 20
    ]
  ]

# Data store
config :occi, model: Mg.Model
config :occi, backend: {OCCI.Backend.Agent, [priv_dir: "data.json"]}

import_config "#{Mix.env()}.exs"
