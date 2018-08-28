defmodule Mg.DNS.Fifo do
  @moduledoc """
  DNS delegate module querying Project Fifo (libsniffle)
  """
  require Logger

  alias Mg.DNS

  @behaviour :erldns_resolver

  @doc """
  erldns_resolver callback
  """
  def get_records_by_name(qname) do
    qname = String.downcase(qname)
    domain = DNS.Conf.get(:domain)

    parts =
      ("^(?<name>.*)\." <> domain <> "$")
      |> Regex.compile!()
      |> Regex.named_captures(qname)

    case parts do
      nil ->
        []

      %{"name" => name} ->
        do_lookup(name)
    end
  end

  ###
  ### Priv
  ###
  defp do_lookup(name) do
    []
  end
end
