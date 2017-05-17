defmodule Mg.Net.Ip do
  use Bitwise
  @moduledoc """
  IP manipulation functions
  """

  @doc """
  Return network part of an address

  ## Examples

      iex> Mg.Net.Ip.network({{255, 255, 255, 255}, 23})
      {{255,255,254,0}, 23}

      iex> Mg.Net.Ip.network({{0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff}, 64})
      {{0xffff, 0xffff, 0xffff, 0xffff, 0, 0, 0, 0}, 64}
  """
  @spec network({:inet.ip_address, integer | :inet.ip_address}) :: {:inet.ip_address, integer}
  def network({addr, prefix}) when is_integer(prefix) do
    network({addr, mask(prefix, tuple_size(addr))})
  end
  def network({addr, mask}) when is_tuple(mask) do
    addr = 0..(tuple_size(addr) - 1) |> Enum.map(&(elem(addr, &1) &&& elem(mask, &1))) |> List.to_tuple
    {addr, prefix(mask)}
  end

  @doc """
  Return broadcast address (IPv4 only)

  ## Examples

      iex> Mg.Net.Ip.broadcast({{255, 255, 255, 255}, 23})
      {{255,255,255,255}, 23}
  """
  @spec broadcast({:inet.ip4_address, integer | :inet.ip4_address}) :: {:inet.ip_address4, integer}
  def broadcast({addr, prefix}) when is_integer(prefix) do
    broadcast({addr, mask(prefix, tuple_size(addr))})
  end
  def broadcast({{_, _, _, _}=addr, mask}) when is_tuple(mask) do
    addr = 0..(tuple_size(addr) - 1) |> Enum.map(fn digit ->
      elem(addr, digit) ||| (0xff ^^^ elem(mask, digit))
    end) |> List.to_tuple
    {addr, prefix(mask)}
  end

  @doc """
  Check if address is reserved

  To complete: a lot of reserved addresses...

  ## Examples

      iex> Mg.Net.Ip.reserved?({{192, 168, 1, 255}, 32}, 24)
      true

      iex> Mg.Net.Ip.reserved?({{192, 255, 1, 0}, 32}, 24)
      true

      iex> Mg.Net.Ip.reserved?({{192, 168, 1, 1}, 32}, 24)
      false

      iex> Mg.Net.Ip.reserved?({{0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff}, 128}, 96)
      false
  """
  @spec reserved?({:inet.ip_address, integer}, integer) :: boolean
  def reserved?({{_, _, _, _}=addr, 32}, netmask) do
    {netaddr, _} = network({addr, netmask})
    {bcaddr, _} = broadcast({addr, netmask})
    (netaddr == addr or bcaddr == addr)
  end
  def reserved?(_, _), do: false

  @doc """
  Get parent IP

  ## Examples

      iex> Mg.Net.Ip.parent({{192, 168, 1, 255}, 32})
      {{192, 168, 1, 254}, 31}

      iex> Mg.Net.Ip.parent({{192, 168, 1, 254}, 32})
      {{192, 168, 1, 254}, 31}

      iex> Mg.Net.Ip.parent({{192, 168, 1, 252}, 1})
      {{0, 0, 0, 0}, 0}
  """
  @spec parent({:inet.ip_address, integer}) :: {:inet.ip_address, integer}
  def parent({addr, prefix}), do: network({addr, prefix - 1})

  @doc """
  Get child IP: mask -> mask + 1
  """
  @spec child({:inet.ip_address, integer}, 0 | 1) :: {:inet.ip_address, integer}
  def child({addr, masklength}, lh) when is_integer(masklength) do
    {digits, full} = case tuple_size(addr) do
                       4 -> {4, 0xff}
                       8 -> {8, 0xff}
                     end
    mask1 = mask(masklength, digits)
    mask2 = mask(masklength + 1, digits)
    dmask = 0..(digits - 1) |> Enum.map(&(elem(mask1, &1) ^^^ elem(mask2, &1))) |> List.to_tuple
    addr = 0..(digits - 1) |> Enum.map(fn d ->
      case lh do
        0 -> elem(addr, d) &&& (full ^^^ elem(dmask, d))
        1 -> elem(addr, d) ||| elem(dmask, d)
      end
    end) |> List.to_tuple
    {addr, masklength + 1}
  end

  @doc """
  Get children IP
  """
  @spec children({:inet.ip_address, integer}) :: { {:inet.ip_address, integer}, {:inet.ip_address, integer} }
  def children({addr, masklength}) do
    { child({addr, masklength}, 0), child({addr, masklength}, 1) }
  end

  @doc """
  Return address type: :inet | :inet6
  """
  @spec inet(:inet.ip_address) :: :inet | :inet6
  def inet(addr) when tuple_size(addr) == 4, do: :inet
  def inet(addr) when tuple_size(addr) == 8, do: :inet6

  ###
  ### Private
  ###

  # prefix length to mask
  defp mask(prefix, digits) do
    {bits, full} = case digits do
                     4 -> {8, 0xff}    # IPv4
                     8 -> {16, 0xffff} # IPv6
                   end
    0..(digits - 1) |> Enum.map(fn d ->
      shift = Enum.min([bits, Enum.max([0, (prefix - (bits * d))])])
      full ^^^ (full >>> shift)
    end) |> List.to_tuple
  end

  # mask to prefix length
  # In fact, only count set bits: if there are cleared bits between set bits, unexpected result can happen !
  def prefix(mask) do
    0..(tuple_size(mask) - 1) |> Enum.reduce(0, &(&2 + popcount(elem(mask, &1))))
  end

  # Implements Brian Kernighan’s Algorithm (see: http://www.geeksforgeeks.org/count-set-bits-in-an-integer/)
  defp popcount(n), do: popcount(n, 0)
  defp popcount(0, acc), do: acc
  defp popcount(i, acc), do: popcount(i &&&  (i - 1), acc + 1)
end
