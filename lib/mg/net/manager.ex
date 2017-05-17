defmodule Mg.Net.Manager do
  use GenServer

  import Ex2ms
  import Mg.Net.Pool
  import Mg.Net.Block

  alias Mg.Net.Pool
  alias Mg.Net.Ip
  alias Mg.Net.Block

  @type policy :: :low | :high | :random
  @type mask :: :unique | integer

  @doc """
  Start the network pool manager
  """
  @spec start_link([String.t | Pool.id]) :: {:ok, pid}
  def start_link(networks) do
    GenServer.start_link(__MODULE__, networks, name: __MODULE__)
  end

  @doc """
  Retrieve networks
  """
  @spec networks() :: [Pool.id]
  def networks() do
    GenServer.call(__MODULE__, :networks)
  end

  @doc """
  Reease address block for a given network.
  """
  @spec lease(Block.id) :: boolean
  def release(block_id) do
    GenServer.call(__MODULE__, {:release, block_id})
  end

  @doc """
  Lease address block for a given network.
  If no block mask, return a /32 (IPv4) or /128 (IPv6) address.

  Opts:
  * policy: :low | :high | :random
  * mask: :unique | integer()
  """
  @spec lease(Pool.id, [policy: policy, mask: mask]) :: Block.t
  def lease(pool_id, opts \\ []) do
    GenServer.call(__MODULE__, {:lease, pool_id, opts})
  end

  @doc """
  Retrieve leases for all polls
  """
  def leases(), do: leases(networks())

  @doc """
  Retrieve leases
  """
  @spec leases(Pool.id | [Pool.id]) :: [Block.t]
  def leases({_, _}=pool_id), do: leases([pool_id])
  def leases(pool_ids), do: GenServer.call(__MODULE__, {:leases, pool_ids})

  ###
  ### Callbacks
  ###
  def init(networks) do
    pools = :ets.new(:pool, [:set, {:keypos, 2}])
    blocks = :ets.new(:block, [:set, {:keypos, 2}])
    networks |> Enum.each(&(true = :ets.insert(pools, Pool.create(&1))))
    {:ok, %{ pools: pools, blocks: blocks }}
  end

  def handle_call({:lease, pool_id, opts}, _from, s) do
    case :ets.lookup(s.pools, pool_id) do
      [] -> {:reply, nil, s}
      [pool] ->
        mask = Pool.valid_mask(pool, Keyword.get(opts, :mask, :unique))
        policy = Keyword.get(opts, :policy, :low)
        init = case :ets.lookup(s.blocks, pool_id) do
                 [] -> block(id: pool_id, pool: pool_id)
                 [block] -> block
               end
        {ret, s} = do_lease(init, mask, policy, s)
        {:reply, ret, s}
    end
  end
  def handle_call({:release, block_id}, _from, s) do
    ms = fun do
      {_, ^block_id, _, :reserved}=b -> b
      {_, ^block_id, _, :lease}=b -> b
    end
    case :ets.select(s.blocks, ms) do
      [] -> {:reply, false, s}
      [block] -> {:reply, true, do_release(block, s)}
    end
  end
  def handle_call(:networks, _from, s) do
    ret = :ets.foldl(fn (pool(id: id), acc) ->
      [ id | acc ]
    end, [], s.pools)
    {:reply, ret, s}
  end
  def handle_call({:leases, pool_ids}, _from, s) do
    ret = pool_ids |> Enum.reduce([], fn id, acc ->
      :ets.match(s.blocks, {:'_', :'$1', id, :lease})
      |> Enum.reduce(acc, fn [block_id], acc2 -> [ block_id | acc2 ] end)
    end)
    {:reply, ret, s}
  end

  ###
  ### Private
  ###
  defp do_lease(block(id: {_, mask}, status: :partial), mask, _policy, s) do
    # Block has been partially leased
    {nil, s}
  end
  defp do_lease(block(id: {_, mask}=block_id, status: :free, pool: {_, netmask})=b, mask, _policy, s) do
    if Ip.reserved?(block_id, netmask) do
      b = block(b, status: :reserved)
      true = :ets.insert(s.blocks, b)
      {nil, s}
    else
      b = block(b, status: :lease)
      true = :ets.insert(s.blocks, b)
      {block_id, s}
    end
  end
  defp do_lease(block(status: status), _mask, _policy, s) when status in [:reserved, :lease] do
    # No available sub-block in this block
    {nil, s}
  end
  defp do_lease(block()=b, mask, policy, s) do
    lh = case policy do
           :random -> Enum.random([0, 1])
           :low -> 0
           :high -> 1
         end
    case do_lease(child(b, lh, s), mask, policy, s) do
      {nil, s} ->
        # No lease available in sub-block
        # Try the other side...
        lh = if lh == 0, do: 1, else: 0
        case do_lease(child(b, lh, s), mask, policy, s) do
          {nil, s} -> {nil, s}
          {lease, s} -> do_lease_update(b, lease, s)
        end
      {lease, s} -> do_lease_update(b, lease, s)
    end
  end

  defp do_lease_update(block()=parent, lease, s) do
    parent = block(parent, status: :partial)
    true = :ets.insert(s.blocks, parent)
    {lease, s}
  end

  defp child(block(id: id, pool: pool_id), lh, s) do
    childaddr = Ip.child(id, lh)
    case :ets.lookup(s.blocks, childaddr) do
      [] -> block(id: childaddr, pool: pool_id)
      [block] -> block
    end
  end

  defp do_release(block(id: block_id, status: :partial)=b, s) do
    Ip.children(block_id) |> Enum.all?(fn id ->
      # true if all child blocks are free
      :ets.lookup(s.blocks, id) == []
    end) |> if(do: true = :ets.delete(s.blocks, block_id))
    do_release_parent(b, s)
  end
  defp do_release(block(id: block_id)=b, s) do
    true = :ets.delete(s.blocks, block_id)
    do_release_parent(b, s)
  end

  defp do_release_parent(block(id: {_, mask}, pool: {_, mask}), s), do: s
  defp do_release_parent(block(id: block_id, pool: pool_id), s) do
    do_release(block(id: Ip.parent(block_id), pool: pool_id, status: :partial), s)
  end
end
