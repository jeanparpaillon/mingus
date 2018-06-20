use Mix.Config

config :mingus,
  ssh: [
    gen_host_key: [:ed25519, :rsa],
    listen: [{"0.0.0.0", 10022}]
  ]

config :mingus,
  dns: [
    listen: [
      {:udp, "0.0.0.0", 10053},
      {:tcp, "0.0.0.0", 10053}
    ]
  ]
