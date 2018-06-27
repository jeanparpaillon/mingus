defmodule Mg.DNS.Query do
  @moduledoc """
  DNS Query records <-> struct functions
  """

  record = Record.extract(:dns_query, from_lib: "kernel/src/inet_dns.hrl")
  keys = :lists.map(&elem(&1, 0), record)
  vals = :lists.map(&{&1, [], nil}, keys)
  pairs = :lists.zip(keys, vals)

  @type native :: :inet_dns.dns_query()
  @type t :: %__MODULE__{}
  defstruct record

  @doc """
  Converts a `DNS.Query` struct to a `:dns_query` record.
  """
  @spec to_record(t) :: :inet_dns.dns_query()
  def to_record(%__MODULE__{unquote_splicing(pairs)}) do
    {:dns_query, unquote_splicing(vals)}
  end

  @doc """
  Converts a `:dns_query` record into a `DNS.Query`.
  """
  @spec from_record(:inet_dns.dns_query()) :: t
  def from_record({:dns_query, unquote_splicing(vals)}) do
    %__MODULE__{unquote_splicing(pairs)}
  end
end
