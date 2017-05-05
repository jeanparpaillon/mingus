defmodule Mg.Net.Manager do
  use GenServer
  alias Mg.Store
  alias Mg.Net.Pool

  @mixin_ipnetwork :"http://schemas.ogf.org/occi/infrastructure/network#ipnetwork"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ###
  ### Callbacks
  ###
  def init(_) do
    networks = Store.get(mixin: @mixin_ipnetwork) |> Enum.map(fn (network) ->
      Pool.new(network)
    end)
    {:ok, networks}
  end
end
