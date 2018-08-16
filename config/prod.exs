use Mix.Config

config :mingus,
  ssh: [
    gen_host_key: [:ed25519],
    listen: [{"0.0.0.0", 22}]
  ]

config :mingus,
  dns: [
    listen: [
      {:udp, "0.0.0.0", 53},
      {:tcp, "0.0.0.0", 53}
    ]
  ]
