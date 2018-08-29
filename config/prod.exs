use Mix.Config

config :mingus,
  ssh: [
    gen_host_key: [:ed25519, :rsa],
    listen: [{"0.0.0.0", 10022}]
  ]

import_config "#{Mix.env()}.secret.exs"
