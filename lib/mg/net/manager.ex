defmodule Mg.Net.Manager do
  @moduledoc """
  Manage IP pools

  Allow IP lease / release / book of IP blocks of any size.  Lease can
  be attributed in ascending, descending or random order. Of course,
  when attributing non /32 (or /128 for IPv6) addresses randomly, you
  may loose IP addresses.

  Manager expect intersection of all pools to be empty. For instance,
  unexpected result will happen if you manage 192.168.1.0/24 and
  192.168.0.0/16 at the same time
  """
  use GenServer
  use Bitwise

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
  @spec start_link([String.t() | Pool.id()]) :: {:ok, pid}
  def start_link(networks) do
    GenServer.start_link(__MODULE__, networks, name: __MODULE__)
  end

  @doc """
  Retrieve networks
  """
  @spec networks() :: [Pool.id()]
  def networks() do
    GenServer.call(__MODULE__, :networks)
  end

  @doc """
  Reease address block for a given network.
  """
  @spec lease(Block.id()) :: boolean
  def release(block_id) do
    GenServer.call(__MODULE__, {:release, block_id})
  end

  @doc """
  Book IP block on a given IP pool.
  Booked blocks can be released with release/1

  Return true in case of success
  """
  @spec book(Block.id()) :: boolean
  def book(block_id) do
    GenServer.call(__MODULE__, {:book, block_id})
  end

  @doc """
  Lease address block for a given network.
  If no block mask, return a /32 (IPv4) or /128 (IPv6) address.

  Opts:
  * policy: :low | :high | :random
  * mask: :unique | integer()
  """
  @spec lease(Pool.id(), policy: policy, mask: mask) :: Block.t()
  def lease(pool_id, opts \\ []) do
    GenServer.call(__MODULE__, {:lease, pool_id, opts})
  end

  @doc """
  Retrieve leases from all pools
  """
  def leases(), do: leases(networks())

  @doc """
  Retrieve leases
  """
  @spec leases(Pool.id() | [Pool.id()]) :: [Block.t()]
  def leases({_, _} = pool_id), do: leases([pool_id])
  def leases(pool_ids), do: GenServer.call(__MODULE__, {:leases, pool_ids})

  # For debugging
  def blocks() do
    GenServer.call(__MODULE__, :blocks)
  end

  ###
  ### Callbacks
  ###
  def init(networks) do
    pools = :ets.new(:pool, [:set, {:keypos, 2}])
    blocks = :ets.new(:block, [:set, {:keypos, 2}])
    networks |> Enum.each(&(true = :ets.insert(pools, Pool.create(&1))))
    {:ok, %{pools: pools, blocks: blocks}}
  end

  def handle_call({:lease, pool_id, opts}, _from, s) do
    case :ets.lookup(s.pools, pool_id) do
      [] ->
        {:reply, nil, s}

      [pool] ->
        mask = Pool.valid_mask(pool, Keyword.get(opts, :mask, :unique))
        policy = Keyword.get(opts, :policy, :low)
        init = init_block(pool_id, s)

        case do_find_block(init, mask, policy, s) do
          nil ->
            {:reply, nil, s}

          lease ->
            {true, s} = do_insert_block(init, block(id: lease, pool: pool_id, status: :lease), s)
            {:reply, lease, s}
        end
    end
  end

  def handle_call({:release, block_id}, _from, s) do
    ms =
      fun do
        {_, ^block_id, _, :reserved} = b -> b
        {_, ^block_id, _, :lease} = b -> b
      end

    case :ets.select(s.blocks, ms) do
      [] -> {:reply, false, s}
      [block] -> {:reply, true, do_release(block, s)}
    end
  end

  def handle_call(:networks, _from, s) do
    {:reply, do_pool_ids(s), s}
  end

  def handle_call({:leases, pool_ids}, _from, s) do
    ret =
      pool_ids
      |> Enum.reduce([], fn id, acc ->
        s.blocks
        |> :ets.match({:_, :"$1", id, :lease})
        |> Enum.reduce(acc, fn [block_id], acc2 -> [block_id | acc2] end)
      end)

    {:reply, ret, s}
  end

  def handle_call({:book, block_id}, _from, s0) do
    {ret, s} =
      s0
      |> do_pool_ids()
      |> Enum.reduce_while({false, s0}, fn
        _, {true, s} ->
          # Found, we stop
          {:halt, {true, s}}

        pool_id, {false, s} ->
          if subblock?(pool_id, block_id) do
            init = init_block(pool_id, s)

            {:cont,
             do_insert_block(init, block(id: block_id, pool: pool_id, status: :reserved), s)}
          else
            # Insert into next pool
            {:cont, {false, s}}
          end
      end)

    {:reply, ret, s}
  end

  def handle_call(:blocks, _from, s) do
    ret = :ets.foldl(&[&1 | &2], [], s.blocks)
    {:reply, ret, s}
  end

  ###
  ### Private
  ###
  defp init_block(pool_id, s) do
    case :ets.lookup(s.blocks, pool_id) do
      [] -> block(id: pool_id, pool: pool_id)
      [block] -> block
    end
  end

  # Block has been partially leased
  defp do_find_block(block(id: {_, mask}, status: :partial), mask, _policy, _s), do: nil

  defp do_find_block(
         block(id: {_, mask} = block_id, status: :free, pool: {_, netmask}),
         mask,
         _policy,
         _s
       ) do
    if Ip.reserved?(block_id, netmask), do: nil, else: block_id
  end

  # No available sub-block in this block
  defp do_find_block(block(status: status), _mask, _policy, _s)
       when status in [:reserved, :lease],
       do: nil

  defp do_find_block(block() = b, mask, policy, s) do
    lh =
      case policy do
        :random -> Enum.random([0, 1])
        :low -> 0
        :high -> 1
      end

    case do_find_block(child(b, lh, s), mask, policy, s) do
      # No lease available in sub-block
      # Try the other side...
      nil ->
        do_find_block(child(b, 1 ^^^ lh, s), mask, policy, s)

      lease ->
        lease
    end
  end

  defp do_insert_block(block(id: {_, prefix}, status: :free), block(id: {_, prefix}) = b, s) do
    true = :ets.insert(s.blocks, b)
    {true, s}
  end

  defp do_insert_block(block(id: {_, prefix}), block(id: {_, prefix}), s) do
    {false, s}
  end

  defp do_insert_block(block(status: status), _b, s) when status in [:lease, :reserved] do
    {false, s}
  end

  defp do_insert_block(block(id: {_, mask}) = acc, block(id: {addr, _}) = b, s) do
    true = :ets.insert(s.blocks, block(acc, status: :partial))
    next_id = Ip.network({addr, mask + 1})

    next =
      case :ets.lookup(s.blocks, next_id) do
        [] -> block(acc, id: next_id, status: :free)
        [block] -> block
      end

    do_insert_block(next, b, s)
  end

  defp child(block(id: id, pool: pool_id), lh, s) do
    childaddr = Ip.child(id, lh)

    case :ets.lookup(s.blocks, childaddr) do
      [] -> block(id: childaddr, pool: pool_id)
      [block] -> block
    end
  end

  defp do_release(block(id: block_id, status: :partial) = b, s) do
    block_id
    |> Ip.children()
    |> Tuple.to_list()
    |> Enum.all?(fn id ->
      # true if all child blocks are free
      :ets.lookup(s.blocks, id) == []
    end)
    |> if(do: true = :ets.delete(s.blocks, block_id))

    do_release_parent(b, s)
  end

  defp do_release(block(id: block_id) = b, s) do
    true = :ets.delete(s.blocks, block_id)
    do_release_parent(b, s)
  end

  defp do_pool_ids(s) do
    :ets.foldl(
      fn pool(id: id), acc ->
        [id | acc]
      end,
      [],
      s.pools
    )
  end

  defp do_release_parent(block(id: {_, mask}, pool: {_, mask}), s), do: s

  defp do_release_parent(block(id: block_id, pool: pool_id), s) do
    do_release(block(id: Ip.parent(block_id), pool: pool_id, status: :partial), s)
  end

  defp subblock?({_, netmask} = pool_id, {addr, _}) do
    Ip.network(pool_id) == Ip.network({addr, netmask})
  end
end
