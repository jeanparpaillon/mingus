defmodule Mg.DNS.Resource do
  @moduledoc """
  DNS records struct <-> records functions
  """

  record = Record.extract(:dns_rr, from_lib: "kernel/src/inet_dns.hrl")
  keys = :lists.map(&elem(&1, 0), record)
  vals = :lists.map(&{&1, [], nil}, keys)
  pairs = :lists.zip(keys, vals)

  @type native :: :inet_dns.dns_rr()
  @type t :: %__MODULE__{}
  defstruct record

  @doc """
  Converts a `DNS.ResourceRecord` struct to a `:dns_rr` record.
  """
  @spec to_record(t) :: native
  def to_record(%__MODULE__{unquote_splicing(pairs)}) do
    {:dns_rr, unquote_splicing(vals)}
  end

  @doc """
  Converts a `:dns_rr` record into a `DNS.ResourceRecord`.
  """
  @spec from_record(native) :: t
  def from_record({:dns_rr, unquote_splicing(vals)}) do
    %__MODULE__{unquote_splicing(pairs)}
  end
end
