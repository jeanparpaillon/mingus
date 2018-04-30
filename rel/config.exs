Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"&^B{N]Ygep<pO!r_8lmRz}hb_S,_p_*|*7}g^<&!vSrT~KYjFoX}X~}TvJJVjo)X"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"I]V9{M(O~*i7Da4Xia6A_eP;M@:O/AXNk8PeHs)?]Q2P[nLeQhZDLxtc*_7*OFUS"
end

release :mingus do
  set version: current_version(:mingus)
  set applications: [ :runtime_tools ]
  set overlays: [
    {:mkdir, "etc"},
    {:template, "priv/mingus.service.eex", "mingus.service"}
  ]
end
