defmodule Mg.DNS.Fifo do
  @moduledoc """
  DNS delegate module querying Project Fifo (libsniffle)
  """
  require Logger
  require Mg.DNS.Records

  use Mg.DNS.Constants

  alias Mg.DNS

  @behaviour :erldns_resolver

  @doc """
  erldns_resolver callback
  """
  def get_records_by_name(qname) do
    qname = String.downcase(qname)
    delegates = DNS.Conf.get(:delegates)

    case match_domain(delegates, qname) do
      nil ->
        []

      {name, domain, org_id} ->
        do_lookup(qname, name, domain, org_id)
    end
  end

  ###
  ### Priv
  ###
  defp match_domain([], _qname), do: nil

  defp match_domain([{r_domain, org_id} | domains], qname) do
    case Regex.named_captures(r_domain, qname) do
      nil ->
        match_domain(domains, qname)

      %{"domain" => domain, "name" => name} ->
        {name, domain, org_id}
    end
  end

  defp do_lookup(qname, name, _domain, org_id) do
    case :ls_vm.get_hostname(name, org_id) do
      {:ok, reply} ->
        build_replies(qname, reply)

      _ ->
        []
    end
  end

  defp build_replies(qname, reply) do
    reply
    |> :ft_hostname.a()
    |> Enum.map(fn {_, ip} -> make_record(qname, :ft_iprange.to_bin(ip)) end)
  end

  defp make_record(qname, ip) do
    {:ok, ip} = :inet.parse_address('#{ip}')

    DNS.Records.dns_rr(
      name: qname,
      type: @_DNS_TYPE_A,
      ttl: 60,
      data: DNS.Records.dns_rrdata_a(ip: ip)
    )
  end
end
