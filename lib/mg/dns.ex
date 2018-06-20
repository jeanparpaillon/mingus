defmodule Mg.DNS do
  @moduledoc """
  Supervise DNS listeners
  """
  import Supervisor.Spec
  require Logger

  alias Mg.Utils

  @doc false
  def child_spec(opts) do
    %{ id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(opts) do
    servers =
      Keyword.get(opts, :listen, [])
      |> Enum.map(fn {family, addr, port} ->
        mod =
          case family do
            :udp -> Mg.DNS.UDP
            :tcp -> Mg.DNS.TCP
          end

        {inet, a} = Utils.binding(addr)
        worker(mod, [inet, a, port], id: :"#{:inet.ntoa(a)}:#{port}/#{family}")
      end)

    pool_opts = [
      name: {:local, :dns_udp_pool},
      worker_module: Mg.DNS.UDPWorker,
      size: 5,
      max_overflow: 10
    ]

    children =
      [
        worker(Mg.DNS.Server, [:dns, opts]),
        :poolboy.child_spec(:dns_udp_pool, pool_opts, [])
      ] ++ servers

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def query(query, opts) do
    case :inet_res.resolve(query.domain, query.class, query.type, opts) do
      {:ok, msg} ->
        rec = Mg.DNS.Record.from_record(msg)

        case rec.anlist do
          [] -> nil
          [res] -> res
        end

      {:error, _} ->
        nil
    end
  end
end
