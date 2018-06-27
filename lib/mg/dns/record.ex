defmodule Mg.DNS.Record do
  @moduledoc """
  Convert records to structs and vice-versa
  """
  alias Mg.DNS
  alias DNS.{Header, Resource, Query}

  record = Record.extract(:dns_rec, from_lib: "kernel/src/inet_dns.hrl")
  keys = :lists.map(&elem(&1, 0), record)
  vals = :lists.map(&{&1, [], nil}, keys)
  pairs = :lists.zip(keys, vals)

  @type native :: :inet_dns.dns_rec()
  @type t :: %__MODULE__{}
  defstruct record

  @doc """
  Converts a `DNS.Record` struct to a `:dns_rec` record.
  """
  @spec to_record(t) :: native
  def to_record(struct) do
    header = Header.to_record(struct.header)
    queries = Enum.map(struct.qdlist, &Query.to_record/1)
    answers = Enum.map(struct.anlist, &Resource.to_record/1)

    _to_record(%{struct | header: header, qdlist: queries, anlist: answers})
  end

  defp _to_record(%__MODULE__{unquote_splicing(pairs)}) do
    {:dns_rec, unquote_splicing(vals)}
  end

  @doc """
  Converts a `:dns_rec` record into a `DNS.Record`.
  """
  @spec from_record(native) :: t
  def from_record({:dns_rec, unquote_splicing(vals)}) do
    struct = %DNS.Record{unquote_splicing(pairs)}

    header = Header.from_record(struct.header)
    queries = Enum.map(struct.qdlist, &Query.from_record(&1))
    answers = Enum.map(struct.anlist, &Resource.from_record(&1))

    %{struct | header: header, qdlist: queries, anlist: answers}
  end

  @doc """
  Decode DNS bin data
  """
  @spec decode(binary) :: {:ok, t} | {:error, term}
  def decode(data) do
    case :inet_dns.decode(data) do
      {:ok, record} -> {:ok, from_record(record)}
      {:error, _} = e -> e
    end
  end

  @doc """
  Encode struct into binary
  """
  @spec encode!(t) :: binary
  def encode!(struct) do
    :inet_dns.encode(to_record(struct))
  end
end
