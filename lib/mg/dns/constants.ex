defmodule Mg.DNS.Constants do
  @moduledoc """
  Use this module to import definitions from 'dns/include/dns.hrl'
  """
  defmacro __using__(_opts) do
    quote do
      require Quaff
      Quaff.include_lib("dns/include/dns.hrl")
    end
  end
end
