use Mix.Config

config :mingus,
  ssh: [
    gen_host_key: [:ed25519, :rsa],
    listen: [{"0.0.0.0", 10022}]
  ]

config :erldns, zone_file: "priv/dns_zones.json"

config :erldns,
  servers: [
    [
      name: :dns_inet11,
      address: '0.0.0.0',
      port: 10053,
      family: :inet,
      processes: 2
    ]
  ]
