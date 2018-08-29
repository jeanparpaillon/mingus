use Mix.Config

config :mingus,
  ssh: [
    gen_host_key: [:ed25519, :rsa],
    listen: [{"0.0.0.0", 10022}]
  ]

config :libsniffle, sniffle: {'10.1.1.240', 4210}

config :erldns, zones: "priv/dns_zones.json"

config :erldns,
  zone_delegates: [
    {"priv.linky.one", Mg.DNS.Fifo}
  ]

config :erldns,
  servers: [
    [name: :inet4, address: '127.0.0.1', port: 10053, family: :inet]
  ]

config :mingus,
  dns: [
    zones: [{"priv.linky.one", "03d4044d-722f-47c3-acec-b5a2f0115e6a"}]
  ]
