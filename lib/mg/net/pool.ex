defmodule Mg.Net.Pool do
  require Record
  alias Mg.Net.Ip

  Record.defrecord(:pool, id: nil)

  @type id :: {:inet.ip_address(), integer}
  @type t :: Record.record(:pool, id: id)

  @doc """
  Create new pool from address + mask or CIDR string
  """
  @spec create({:inet.ip_address(), integer} | String.t()) :: Pool.t()
  def create({{_, _, _, _} = addr, mask}), do: new({addr, mask})
  def create({{_, _, _, _, _, _, _, _} = addr, mask}), do: new({addr, mask})

  def create(cidr) when is_binary(cidr) or is_list(cidr) do
    {addr, mask} = parse(cidr)
    new({addr, mask})
  end

  def valid_mask(pool(id: {addr, _}), :unique) when tuple_size(addr) == 4, do: 32
  def valid_mask(pool(id: {addr, _}), :unique) when tuple_size(addr) == 8, do: 128

  def valid_mask(pool(id: {addr, netmask}), mask)
      when tuple_size(addr) == 4 and mask <= 32 and mask >= netmask do
    mask
  end

  def valid_mask(pool(id: {addr, netmask}), mask)
      when tuple_size(addr) == 8 and mask <= 128 and mask >= netmask do
    mask
  end

  ###
  ### Private
  ###
  defp new({addr, mask}) do
    pool(id: Ip.network({addr, mask}))
  end

  defp parse(cidr) do
    [addr, mask] = String.split(cidr, "/")
    {:ok, addr} = :inet.parse_address('#{addr}')
    {mask, ""} = Integer.parse(mask)
    {addr, mask}
  end
end
