defmodule Mg.Net.Pool do
  use Bitwise
  require Logger
  alias Mg.Net.Pool

  defstruct ip: nil, mask: 0, status: :free, low: nil, high: nil, type: :inet, netmask: 0

  @type t :: %Pool{}
  @type policy :: :low | :high | :random
  @type mask :: :unique | integer
  @type status :: :free | :partial | :lease | :reserved

  @doc """
  Create new pool from address + mask or CIDR string

  ## Examples

      iex> Mg.Net.Pool.new({192, 168, 100, 231}, 24)
      %Mg.Net.Pool{free: true, high: nil, ip: <<192, 168, 100, 0>>, low: nil, mask: 24, netmask: 24, type: :inet}
  """
  @spec new(:inet.ip_address, number) :: Pool.t
  def new({_, _, _, _}=addr, mask), do: new(addr, mask, :inet)
  def new({_, _, _, _, _, _, _, _}=addr, mask), do: new(addr, mask, :inet6)

  @doc """
  Create new pool from address + mask or CIDR string

  ## Examples

      iex> Mg.Net.Pool.new({{192, 168, 100, 231}, 24})
      %Mg.Net.Pool{free: true, high: nil, ip: <<192, 168, 100, 0>>, low: nil, mask: 24, netmask: 24, type: :inet}

      iex> Mg.Net.Pool.new("192.168.100.231/24")
      %Mg.Net.Pool{free: true, high: nil, ip: <<192, 168, 100, 0>>, low: nil, mask: 24, netmask: 24, type: :inet}

      iex> Mg.Net.Pool.new("176.31.90.160/27")
      %Mg.Net.Pool{free: true, high: nil, ip: <<176, 31, 90, 160>>, low: nil, mask: 27, netmask: 27, type: :inet}

      iex> Mg.Net.Pool.new("5.39.110.160/27")
      %Mg.Net.Pool{free: true, high: nil, ip: <<5, 39, 110, 160>>, low: nil, mask: 27, netmask: 27, type: :inet}
  """
  @spec new({:inet.ip_address, number} | String.t) :: Pool.t
  def new({{_, _, _, _}=addr, mask}), do: new(addr, mask, :inet)
  def new({{_, _, _, _, _, _, _, _}=addr, mask}), do: new(addr, mask, :inet6)
  def new(cidr) when is_binary(cidr) or is_list(cidr) do
    {type, addr, mask} = parse(cidr)
    new(addr, mask, type)
  end

  @doc """
  Lease address block from the pool.
  If no block mask, return a /32 (IPv4) or /128 (IPv6) address.

  Opts:
  * policy: :low | :high | :random
  * mask: :unique | integer()
  """
  @spec lease(Pool.t, [policy: policy, mask: mask]) :: {Pool.t, nil | {:inet.ip_address, number}}
  def lease(pool, opts \\ []) do
    block_mask = get_block_mask(pool, Keyword.get(opts, :mask, :unique))
    policy = Keyword.get(opts, :policy, :low)
    do_lease(pool, block_mask, policy)
  end

  @doc """
  Set reserved address or block
  """
  @spec reserved(Pool.t, :inet.ip_address, number) :: Pool.t
  def reserved(%Pool{ type: type }=p, addr, mask \\ 0) do
    mask = if mask == 0 do
      case type do
        :inet -> 32
        :inet6 -> 128
      end
    else
      mask
    end
    block = %Pool{ ip: addr_to_binary(addr), type: inet?(addr), mask: mask, status: :reserved, netmask: p.netmask }
    case do_insert(p, block) do
      # Silently returns original pool
      :error -> p
      updated -> updated
    end
  end

  @doc """
  Return leases
  """
  @spec leases(Pool.t) :: [ {:inet.ip_address, number} ]
  def leases(p), do: by_status(p, :lease, [])

  @doc """
  Return reserved blocks
  """
  @spec reserved(Pool.t) :: [ {:inet.ip_address, number} ]
  def reserved(p), do: by_status(p, :reserved, [])

  ###
  ### Private
  ###
  defp new(addr, mask, type) do
    bin = addr_to_binary(addr)
    rest_size = bit_size(bin) - mask
    << addr :: size(mask), _ :: bits >> = bin
    %Pool{ ip: << addr :: size(mask), 0 :: size(rest_size) >>, mask: mask, type: type, netmask: mask }
  end

  defp parse(cidr) do
    [addr, mask] = String.split(cidr, "/")
    {:ok, addr} = :inet.parse_address('#{addr}')
    {mask, ""} = Integer.parse(mask)
    {inet?(addr), addr, mask}
  end

  defp addr_to_binary(addr) do
    size = tuple_size(addr) - 1
    b_size = tuple_size(addr) * 2
    0..size |> Enum.reduce(<<>>, fn (i, acc) ->
      acc <> << elem(addr, i) :: size(b_size) >>
    end)
  end

  defp by_status(nil, _, acc), do: acc
  defp by_status(%Pool{ ip: ip, mask: mask, status: status }, status, acc) do
    [ to_cidr(ip, mask) | acc ]
  end
  defp by_status(%Pool{}=p, status, acc) do
    by_status(low(p), status, acc) ++ by_status(high(p), status, acc) ++ acc
  end

  defp do_lease(%Pool{ mask: mask, status: :partial }=p, mask, _policy) do
    # Block has been partially reserved, can not find sub-block
    {p, nil}
  end
  defp do_lease(%Pool{ ip: ip, mask: mask, status: :free }=p, mask, _policy) do
    # This block is available or reserved
    if reserved?(p) do
      {%{ p | status: :reserved }, nil}
    else
      {%{ p | status: :lease }, to_cidr(ip, mask)}
    end
  end
  defp do_lease(%Pool{ status: status }=p, _mask, _policy) when status == :reserved or status == :lease do
    # No available sub-block in this block
    {p, nil}
  end
  defp do_lease(%Pool{}=p, block_mask, policy) do
    lh = case policy do
           :random -> Enum.random([:low, :high])
           _ -> policy
         end
    case do_lease(sub_block(p, lh), block_mask, policy) do
      # No lease available in sub-block
      {_, nil} ->
        # Try the other side...
        lh = if lh == :low, do: :high, else: :low
        case do_lease(sub_block(p, lh), block_mask, policy) do
          {_sub, nil} -> {p, nil}
          {sub, block} -> {update_pool(p, sub, lh), block}
        end
      # A lease has been found in sub-block, update pool
      {sub, block} -> {update_pool(p, sub, lh), block}
    end
  end

  defp do_insert(%Pool{ mask: mask, status: :free }, %Pool{ mask: mask }=block), do: block
  defp do_insert(%Pool{ status: :reserved }, _block), do: :error
  defp do_insert(%Pool{ status: :lease },    _block), do: :error
  defp do_insert(%Pool{ ip: parent_ip, mask: parent_mask }=p, %Pool{ ip: block_ip }=block) do
    rest_size = bit_size(parent_ip) - parent_mask - 1
    << _ :: size(parent_mask), lh :: size(1), _ :: size(rest_size) >> = block_ip
    sub = sub_block(p, lh)
    case do_insert(sub, block) do
      :error -> :error
      sub ->
        if lh == 0 do
          %Pool{ p | low: sub, status: :partial }
        else
          %Pool{ p | high: sub, status: :partial }
        end
    end
  end

  defp sub_block(%Pool{ low: low }=p, 0),       do: low  || new_sub_block(p, 0)
  defp sub_block(%Pool{ low: low }=p, :low),    do: low  || new_sub_block(p, 0)
  defp sub_block(%Pool{ high: high }=p, 1),     do: high || new_sub_block(p, 1)
  defp sub_block(%Pool{ high: high }=p, :high), do: high || new_sub_block(p, 1)

  # Returns a block with netmask increased by one
  defp new_sub_block(%Pool{ ip: ip, mask: mask, netmask: netmask }, next_bit) do
    << base :: size(mask), _ :: bits >> = ip
    lower_size = bit_size(ip) - mask - 1
    %Pool{
      ip: << base :: size(mask), next_bit :: size(1), 0 :: size(lower_size) >>,
      mask: mask + 1,
      netmask: netmask
    }
  end

  defp update_pool(p, block, :low), do: update_status(%Pool{ p | low: block })
  defp update_pool(p, block, :high), do: update_status(%Pool{ p | high: block })

  defp update_status(%Pool{ low: nil, high: nil }=p), do: %Pool{ p | status: :free }
  defp update_status(%Pool{}=p), do: %Pool{ p | status: :partial }

  defp to_cidr(b, mask) do
    zero_size = bit_size(b) - mask
    << ip :: size(mask), _ :: size(zero_size) >> = b
    unit_size = if bit_size(b) == 32, do: 8, else: 16
    to_cidr(<< ip :: size(mask), 0 :: size(zero_size) >>, mask, unit_size, [])
  end

  defp to_cidr(<<>>, mask, _, acc), do: {List.to_tuple(Enum.reverse(acc)), mask}
  defp to_cidr(ip, mask, unit_size, acc) do
    << h :: size(unit_size), rest :: binary >> = ip
    to_cidr(rest, mask, unit_size, [ h | acc])
  end

  defp get_block_mask(%Pool{ type: :inet }, :unique), do: 32
  defp get_block_mask(%Pool{ type: :inet6 }, :unique), do: 128
  defp get_block_mask(%Pool{ type: :inet,  mask: netmask }, mask)
  when mask <= 32 and mask >= netmask do
    mask
  end
  defp get_block_mask(%Pool{ type: :inet6, mask: netmask }, mask)
  when mask <= 128 and mask >= netmask do
    mask
  end
  defp get_block_mask(%Pool{ type: type, mask: netmask }, mask) do
    max = if type == :inet, do: 32, else: 128
    raise "Invalid block size (min: #{netmask}, max: #{max}): #{mask}"
  end

  defp reserved?(%Pool{ ip: ip, mask: mask }=pool) do
    mask == bit_size(ip) and (netaddr(pool) == ip or broadcast(pool) == ip)
  end

  defp netaddr(%Pool{ ip: ip, netmask: netmask }) do
    rest_size = bit_size(ip) - netmask
    << netaddr :: size(netmask), _ :: size(rest_size) >> = ip
    << netaddr :: size(netmask), 0 :: size(rest_size) >>
  end

  defp broadcast(%Pool{ ip: ip, netmask: netmask }) do
    rest_size = bit_size(ip) - netmask
    << netaddr :: size(netmask), _ :: size(rest_size) >> = ip
    rest = 1..rest_size |> Enum.reduce(0, fn _, acc -> (acc <<< 1) + 1 end)
    << netaddr :: size(netmask), rest :: size(rest_size) >>
  end

  defp low(%Pool{ low: low }), do: low
  defp high(%Pool{ high: high }), do: high

  defp inet?({_, _, _, _}), do: :inet
  defp inet?({_, _, _, _, _, _, _, _}), do: :inet6
end
