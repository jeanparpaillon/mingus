defmodule Mg.Net.Ip do
  use Bitwise
  @moduledoc """
  IP manipulation functions
  """

  @doc """
  Return network part of an address
  """
  @spec network(:inet.ip_address, integer | :inet.ip_address) :: :inet.ip_address
  def network(addr, masklength) when is_integer(masklength) do
    network(addr, mask(masklength, tuple_size(addr)))
  end
  def network(addr, mask) when is_tuple(mask) do
    0..(tuple_size(addr) - 1) |> Enum.map(&(elem(addr, &1) &&& elem(mask, &1))) |> List.to_tuple
  end

  @doc """
  Return broadcast address
  """
  @spec broadcast(:inet.ip_address, integer | :inet.ip_address) :: :inet.ip_address
  def broadcast(addr, masklength) when is_integer(masklength) do
    broadcast(addr, mask(masklength, tuple_size(addr)))
  end
  def broadcast(addr, mask) when is_tuple(mask) do
    0..(tuple_size(addr) - 1) |> Enum.map(&(elem(addr, &1) &&& (~~~ elem(mask, &1)))) |> List.to_tuple
  end

  @doc """
  Check if address is reserved
  """
  @spec reserved?(:inet.ip_address, integer) :: boolean
  def reserved?(addr, netmask) do
    (network(addr, netmask) == addr or broadcast(addr, netmask) == addr)
  end

  @doc """
  Get next IP
  """
  @spec next(:inet.ip_address, integer, 0 | 1) :: :inet.ip_address
  def next(addr, masklength, lh) when is_integer(masklength) do
    digits = tuple_size(addr)
    mask1 = mask(masklength, digits)
    mask2 = mask(masklength + 1, digits)
    dmask = 0..(digits - 1) |> Enum.map(&(elem(mask1, &1) ^^^ elem(mask2, &1))) |> List.to_tuple
    0..(digits - 1) |> Enum.map(fn d ->
      case lh do
        0 -> elem(addr, d) &&& (~~~ elem(dmask, d))
        1 -> elem(addr, d) ||| elem(dmask, d)
      end
    end) |> List.to_tuple
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
  def mask(length, digits) do
    {bits, full} = case digits do
                     4 -> {8, 0xff}    # IPv4
                     8 -> {16, 0xffff} # IPv6
                   end
    0..(digits - 1) |> Enum.map(fn d ->
      shift = Enum.min([bits, Enum.max([0, (length - (bits * d))])])
      ~~~ (full >>> shift)
    end) |> List.to_tuple
  end
end
