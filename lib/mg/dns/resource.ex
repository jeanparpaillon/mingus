defmodule Mg.DNS.Resource do
  @moduledoc """
  DNS records struct <-> records functions
  """

  record = Record.extract(:dns_rr, from_lib: "kernel/src/inet_dns.hrl")
  keys = :lists.map(&elem(&1, 0), record)
  vals = :lists.map(&{&1, [], nil}, keys)
  pairs = :lists.zip(keys, vals)

  defstruct record
  @type t :: %__MODULE__{}

  @doc """
  Converts a `DNS.ResourceRecord` struct to a `:dns_rr` record.
  """
  def to_record(%Mg.DNS.Resource{unquote_splicing(pairs)}) do
    {:dns_rr, unquote_splicing(vals)}
  end

  @doc """
  Converts a `:dns_rr` record into a `DNS.ResourceRecord`.
  """
  def from_record(dns_rr)

  def from_record({:dns_rr, unquote_splicing(vals)}) do
    %Mg.DNS.Resource{unquote_splicing(pairs)}
  end
end
