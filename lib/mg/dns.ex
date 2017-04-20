defmodule Mg.DNS do
  import Supervisor.Spec
  require Logger

  def start_link(opts) do
    servers = Keyword.get(opts, :listen, [])
    |> Enum.map(fn {family, s_addr, port} ->
      mod = case family do
	            :udp -> Mg.DNS.UDP;
	            :tcp -> Mg.DNS.TCP
	          end
      case :inet.parse_address('#{s_addr}') do
	      {:ok, {_,_,_,_}=a} ->
	        worker(mod, [:inet, a, port], id: :"#{s_addr}:#{port}/#{family}")
	      {:ok, {_,_,_,_,_,_,_,_}=a} ->
	        worker(mod, [:inet6, a, port], id: :"[#{s_addr}]:#{port}/#{family}")
      end
    end)

    pool_opts = [
      name: {:local, :dns_udp_pool},
      worker_module: Mg.DNS.UDPWorker,
      size: 5,
      max_overflow: 10
    ]

    children = [
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
      {:error, _} -> nil
    end
  end

  defmodule UDP do
    require Logger
    use GenServer

    def start_link(inet, addr, port) do
      GenServer.start_link(__MODULE__, [inet, addr, port])
    end

    def init([inet, addr, port]) do
      opts = [ :binary, {:active, 100}, {:read_packets, 1000}, inet ]
      opts = case addr do
	             {0,0,0,0} -> opts
	             {0,0,0,0,0,0,0,0} -> opts
	             _ -> [ {:ip, addr} | opts ]
	           end
      Logger.info("<DNS> listen on udp://#{:inet.ntoa(addr)}:#{port}")
      :gen_udp.open(port, opts)
    end

    def handle_info({:udp, socket, host, port, bin}, socket) do
      msg = {:query, socket, host, port, bin}
      :poolboy.transaction(:dns_udp_pool, &(GenServer.cast(&1, msg)))
      {:noreply, socket}
    end

    def handle_info({:udp_socket, socket}, socket) do
      :inet.setopts(socket, [active: 100])
      {:noreply, socket}
    end
  end

  defmodule UDPWorker do
    use GenServer

    def start_link(_), do: GenServer.start_link(__MODULE__, [])

    def init(_), do: {:ok, :ok}

    def handle_cast({:query, socket, from, port, bin}, :ok) do
      case GenServer.call(:dns, {:query, from, port, bin}) do
	      {:ok, ans} ->
	        :ok = :gen_udp.send(socket, from, port, ans)
	        {:noreply, :ok}
	      {:error, _err} ->
	        {:noreply, :ok}
      end
    end
  end

  defmodule TCP do
    require Logger

    def start_link(inet, addr, port) do
      opts = [:binary, {:active, 100}, {:reuseaddr, true},
	            {:ip, addr}, {:port, port}, inet]
      Logger.info("<DNS> listen on tcp://#{:inet.ntoa(addr)}:#{port}")
      :ranch.start_listener(:dns_tcp, 10, :ranch_tcp, opts, Mg.DNS.TCPProtocol, [])
    end
  end

  defmodule TCPProtocol do
    require Logger

    def start_link(ref, socket, transport, opts) do
      pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
      {:ok, pid}
    end

    def init(ref, socket, transport, _opts) do
      :ok = :ranch.accept_ack(ref)
      loop(socket, transport, "")
    end

    def loop(socket, transport, _acc) do
      case transport.recv(socket, 0, 5000) do
	      {:ok, ""} -> :ok
	      {:ok, data} ->
	        case :inet.peername(socket) do
	          {:ok, {from, port}} ->
	            case GenServer.call(:dns, {:query, from, port, data}) do
		            {:ok, ans} -> transport.send(socket, ans)
		            {:error, _err} -> :ok
	            end
	          {:error, err} ->
	            Logger.debug("<dns> tcp error: #{inspect err}")
	            :ok
	        end
	      _ ->
	        :ok = transport.close(socket)
      end
    end
  end
end
