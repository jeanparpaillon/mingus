defmodule Mg.DNS.Header do
  @moduledoc """
  DNS Headers struct <-> records functions
  """

  record = Record.extract(:dns_header, from_lib: "kernel/src/inet_dns.hrl")
  keys = :lists.map(&elem(&1, 0), record)
  vals = :lists.map(&{&1, [], nil}, keys)
  pairs = :lists.zip(keys, vals)

  defstruct record
  @type t :: %__MODULE__{}

  @doc """
  Converts a `DNS.Header` struct to a `:dns_header` record.
  """
  def to_record(%Mg.DNS.Header{unquote_splicing(pairs)}) do
    {:dns_header, unquote_splicing(vals)}
  end

  @doc """
  Converts a `:dns_header` record into a `DNS.Header`.
  """
  def from_record(file_info)

  def from_record({:dns_header, unquote_splicing(vals)}) do
    %Mg.DNS.Header{unquote_splicing(pairs)}
  end
end
