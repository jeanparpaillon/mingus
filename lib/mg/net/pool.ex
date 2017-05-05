defmodule Mg.Net.Pool do
  use Bitwise
  require Logger
  alias Mg.Net.Pool

  defstruct ip: nil, mask: 0, free: true, low: nil, high: nil, type: :inet, netmask: 0

  @doc """
  Create new pool from address + mask or CIDR string

  ## Examples

      iex> Mg.Net.Pool.new("192.168.100.231/24")
      %Mg.Net.Pool{free: true, high: nil, ip: <<192, 168, 100, 0>>, low: nil, mask: 24, netmask: 24, type: :inet}

      iex> Mg.Net.Pool.new("176.31.90.160/27")
      %Mg.Net.Pool{free: true, high: nil, ip: <<176, 31, 90, 160>>, low: nil, mask: 27, netmask: 27, type: :inet}

      iex> Mg.Net.Pool.new("5.39.110.160/27")
      %Mg.Net.Pool{free: true, high: nil, ip: <<5, 39, 110, 160>>, low: nil, mask: 27, netmask: 27, type: :inet}
  """
  def new({_, _, _, _}=addr, mask), do: new(addr, mask, :inet)
  def new({_, _, _, _, _, _, _, _}=addr, mask), do: new(addr, mask, :inet6)

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
  def lease(pool, opts \\ []) do
    block_mask = get_block_mask(pool, Keyword.get(opts, :mask, :unique))
    policy = Keyword.get(opts, :policy, :low)
    do_lease(pool, block_mask, policy)
  end

  @doc """
  Return /32 (IPv4) or /128 (IPv6) leases
  """
  def leases(p), do: leases(p, [])

  ###
  ### Private
  ###
  defp new(addr, mask, type) do
    rest_size = bit_size(addr) - mask
    << addr :: size(mask), _ :: bits >> = addr
    %Pool{ ip: << addr :: size(mask), 0 :: size(rest_size) >>, mask: mask, type: type, netmask: mask }
  end

  defp leases(nil, acc), do: acc
  defp leases(%Pool{ ip: ip, mask: mask, free: false }, acc) when bit_size(ip) == mask do
    {addr, _} = to_cidr(ip, mask)
    [ addr | acc ]
  end
  defp leases(%Pool{ low: low, high: high }, acc) do
    leases(low) ++ leases(high) ++ acc
  end

  defp do_lease(%Pool{ ip: ip, mask: mask, free: true }=p, mask, _policy) do
    # This block is available or reserved
    p = %{ p | free: false }
    if reserved?(p), do: {p, nil}, else: {p, to_cidr(ip, mask)}
  end
  defp do_lease(%Pool{ free: false }=p, _mask, _policy) do
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

  defp sub_block(%Pool{ low: low, high: _ }=p,    :low), do: low || new_sub_block(p, 0)
  defp sub_block(%Pool{ low: _,   high: high }=p, :high), do: high || new_sub_block(p, 1)

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

  defp update_pool(pool, block, :low),  do: update_free(%{ pool | low: block })
  defp update_pool(pool, block, :high), do: update_free(%{ pool | high: block })

  defp update_free(%Pool{ low: %Pool{ free: false }, high: %Pool{ free: false } }=p), do: %{ p | free: false }
  defp update_free(p), do: %{ p | free: true }

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

  defp parse(cidr) do
    [addr, mask] = String.split(cidr, "/")
    {:ok, addr} = :inet.parse_address('#{addr}')
    {mask, ""} = Integer.parse(mask)
    type = case tuple_size(addr) do
             4 -> :inet
             8 -> :inet6
           end
    {type, addr_to_binary(addr), mask}
  end

  defp addr_to_binary(addr) do
    size = tuple_size(addr) - 1
    b_size = tuple_size(addr) * 2
    0..size |> Enum.reduce(<<>>, fn (i, acc) ->
      acc <> << elem(addr, i) :: size(b_size) >>
    end)
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

  def netaddr(%Pool{ ip: ip, netmask: netmask }) do
    rest_size = bit_size(ip) - netmask
    << netaddr :: size(netmask), _ :: size(rest_size) >> = ip
    << netaddr :: size(netmask), 0 :: size(rest_size) >>
  end

  def broadcast(%Pool{ ip: ip, netmask: netmask }) do
    rest_size = bit_size(ip) - netmask
    << netaddr :: size(netmask), _ :: size(rest_size) >> = ip
    rest = 1..rest_size |> Enum.reduce(0, fn _, acc -> (acc <<< 1) + 1 end)
    << netaddr :: size(netmask), rest :: size(rest_size) >>
  end
end
