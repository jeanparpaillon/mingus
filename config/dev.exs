use Mix.Config

config :mingus,
  ssh: [
    gen_host_key: [:ed25519, :rsa],
    listen: [{"0.0.0.0", 10022}]
  ]

config :mingus,
  fifo_services: [
    sniffle: {'10.1.1.240', 4210}
  ]

config :mingus,
  dns: [
    servers: [{"0.0.0.0", 10053, processes: 2}],
    zones: [
      {:file, "priv/dns_zones.json"},
      {:fifo, "cloud.example.com", "03d4044d-722f-47c3-acec-b5a2f0115e6a"},
      {:fifo, "priv.example.com", "aaaaa"}
    ]
  ]
