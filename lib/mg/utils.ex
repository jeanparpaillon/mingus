defmodule Mg.Utils do
  @moduledoc """
  Some facilities
  """

  @doc """
  Transform string representation of IP address into ient family
  and erlang internal representation of address.

  ## Parameters

   - addr: String that represents the address

  ## Returns

   - {:inet, ip_address()}
   - {:inet6, ip_address()}
   - {:inet, {127, 0, 0, 1}}

  """
  def binding(addr) do
    case :inet.getaddr('#{addr}', :inet) do
      {:ok, a} -> {:inet, a}
      {:error, _} ->
        case :inet.getaddr('#{addr}', :inet6) do
          {:ok, a} -> {:inet6, a}
          {:error, _} -> {:inet, {127, 0, 0, 1}}
        end
    end
  end
end
