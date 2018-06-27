defmodule Mg.DNS.Header do
  @moduledoc """
  DNS Headers struct <-> records functions
  """

  record = Record.extract(:dns_header, from_lib: "kernel/src/inet_dns.hrl")
  keys = :lists.map(&elem(&1, 0), record)
  vals = :lists.map(&{&1, [], nil}, keys)
  pairs = :lists.zip(keys, vals)

  @type native :: :inet_dns.dns_header()
  @type t :: %__MODULE__{}
  defstruct record

  @doc """
  Converts a `Mg.DNS.Header` struct to a `:dns_header` record.
  """
  @spec to_record(t) :: native
  def to_record(%__MODULE__{unquote_splicing(pairs)}) do
    {:dns_header, unquote_splicing(vals)}
  end

  @doc """
  Converts a `:dns_header` record into a `DNS.Header`.
  """
  @spec from_record(native) :: t
  def from_record({:dns_header, unquote_splicing(vals)}) do
    %__MODULE__{unquote_splicing(pairs)}
  end
end
