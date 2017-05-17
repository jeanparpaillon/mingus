defmodule Mg.Net do
  import Supervisor.Spec
  alias Mg.Store

  @mixin_ipnetwork :"http://schemas.ogf.org/occi/infrastructure/network#ipnetwork"

  def start_link(_opts) do
    networks = Store.get(mixin: @mixin_ipnetwork) |> Enum.map(fn network ->
      network[:attributes][:"occi.network.address"]
    end)
    srv = [
      worker(Mg.Net.Manager, [networks])
    ]
    Supervisor.start_link(srv, strategy: :one_for_one)
  end
end
