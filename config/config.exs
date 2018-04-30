[
  mingus: [
    id: "kbrw",
    ssh: [
      gen_host_key: true,
      listen: [
        {"0.0.0.0", 10022}
      ]
    ],
    dns: [
      nameservers: [
	      { {8,8,8,8}, 53 }
      ],
      listen: [
	      {:udp, "0.0.0.0", 10053},
	      {:tcp, "0.0.0.0", 10053},
      ]
    ],
    net: [],
    providers: [
      {Mg.Providers.Ovh, :kbrw, [token: "XXX"]}
    ]
  ],
  occi: [
    model: Mg.Model,
    backend: { OCCI.Backend.Agent, [priv_dir: "data.json"] }
  ]
]
