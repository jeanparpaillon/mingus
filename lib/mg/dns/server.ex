defmodule Mg.DNS.Server do
  require Logger
  use GenServer
  alias Mg.DNS

  @kind_application :'http://schemas.ogf.org/occi/platform#application'
  @kind_component :'http://schemas.ogf.org/occi/platform#component'

  def start_link(name, opts, store) do
    GenServer.start_link(__MODULE__, [opts, store], name: name)
  end

  # Callbacks
  def init([opts, store_url]) do
    Logger.debug("Start DNS (store: #{store_url})")
    s = %{
      store: OCCI.from_file(store_url),
      nameservers: Keyword.get(opts, :nameservers)
    }
    {:ok, s}
  end

  def handle_call({:query, from, port, data}, _from, s) do
    case DNS.Record.decode(data) do
      {:ok, q} ->
        ans = handle_msg(q, {from, port}, s)
        {:reply, {:ok, DNS.Record.encode!(ans)}, s}
      {:error, _}=e ->
        {:reply, e, s}
    end
  end

  #
  # Private
  #
  defp handle_msg(msg, from, s) do
    ans = msg.qdlist |> Enum.reduce([], fn (q, acc) ->
      case handle_query(q, from, s) do
        nil -> acc
        rec -> [ rec | acc ]
      end
    end)
    %{msg | anlist: ans}
  end

  defp handle_query(q, {host, _port}, s) do
    case OCCI.get(s.store, kind: @kind_application, ip: host) do
      [] ->
        # From unknown app
        DNS.query(q, [nameservers: s.nameservers])
      [app] ->
        # From know app
        Logger.debug("QUERY from #{inspect host}: #{inspect q}")
        ip = app.links |> Enum.filter
        %DNS.Resource{
          domain: q.domain,
          class: q.class,
          type: q.type,
          ttl: 0,
          data: {127,0,0,1}
        }
    end
  end
end
