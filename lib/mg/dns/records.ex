defmodule Mg.DNS.Records do
  @moduledoc """
  Records from dns_erlang lib
  """
  require Record

  Record.defrecord(
    :dns_rr,
    Record.extract(:dns_rr, from_lib: "dns/include/dns_records.hrl")
  )

  Record.defrecord(
    :dns_rrdata_a,
    Record.extract(:dns_rrdata_a, from_lib: "dns/include/dns_records.hrl")
  )
end
