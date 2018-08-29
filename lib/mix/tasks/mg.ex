defmodule Mix.Tasks.Mg do
  @moduledoc """
  Mingus configuration functions
  """
  @shortdoc "Generates Mingus configuration"
  use Mix.Task

  @doc """
  Generates Mingus configuration
  """
  def run(_args) do
    :mingus
    |> Application.get_env(:dns, [])
    |> erldns_env()
    |> set_env(:erldns)

    :mingus
    |> Application.get_env(:fifo_services, [])
    |> libsniffle_env([])
    |> set_env(:libsniffle)

    :ok
  end

  ###
  ### Priv
  ###
  defp set_env(env, app) do
    env
    |> Enum.each(fn {name, value} ->
      Application.put_env(app, name, value, persistent: true)
    end)
  end

  defp libsniffle_env([], env), do: env

  defp libsniffle_env([{:sniffle, :mdns} | opts], env) do
    libsniffle_env(opts, [{:sniffle, :mdns} | env])
  end

  defp libsniffle_env([{:sniffle, {address, port}} | opts], env) do
    libsniffle_env(opts, [{:sniffle, {'#{address}', port}} | env])
  end

  defp erldns_env(opts) do
    env0 = [
      catch_exceptions: false,
      use_root_hints: true,
      dnssec: [enabled: true],
      servers: [],
      pools: [{:tcp_worker_pool, :erldns_worker, [size: 10, max_overflow: 20]}]
    ]

    erldns_env(opts, env0)
  end

  defp erldns_env([], env), do: env

  defp erldns_env([{:servers, servers} | opts], env) do
    servers_opts =
      servers
      |> Enum.map(&server_opts/1)

    erldns_env(opts, Keyword.put(env, :servers, servers_opts))
  end

  defp erldns_env([{:zones, zones} | opts], env) do
    erldns_env(opts, zones_opts(zones, env))
  end

  defp erldns_env([{:pool, pool} | opts], env) do
    pool_def = {:tcp_worker_pool, :erldns_worker, pool}
    erldns_env(opts, Keyword.put(env, :pools, [pool_def]))
  end

  defp server_opts({address, port}), do: server_opts({address, port, []})

  defp server_opts({address, port, server_opts}) do
    family =
      case :inet.parse_address('#{address}') do
        {:ok, {_, _, _, _}} -> :inet
        {:ok, {_, _, _, _, _, _, _, _}} -> :inet6
      end

    [
      name: :"#{address}:#{port}",
      address: '#{address}',
      port: port,
      family: family
    ]
    |> Enum.concat(server_opts)
  end

  defp zones_opts([], env), do: env

  defp zones_opts([{:file, path} | zones], env) do
    zones_opts(zones, Keyword.put(env, :zones, path))
  end

  defp zones_opts([{:fifo, domain, _org_id} | zones], env) do
    delegates =
      env
      |> Keyword.get(:zone_delegates, [])
      |> Enum.concat([{domain, Mg.DNS.Fifo}])

    zones_opts(zones, Keyword.put(env, :zone_delegates, delegates))
  end
end
