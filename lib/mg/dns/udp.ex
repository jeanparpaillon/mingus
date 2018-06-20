defmodule Mg.DNS.UDP do
  @moduledoc """
  DNS UDP server
  """
  require Logger
  use GenServer

  def start_link(inet, addr, port) do
    GenServer.start_link(__MODULE__, [inet, addr, port])
  end

  def init([inet, addr, port]) do
    opts = [:binary, {:active, 100}, {:read_packets, 1000}, inet]

    opts =
      case addr do
        {0, 0, 0, 0} -> opts
        {0, 0, 0, 0, 0, 0, 0, 0} -> opts
        _ -> [{:ip, addr} | opts]
      end

    Logger.info("<DNS> listen on udp://#{:inet.ntoa(addr)}:#{port}")
    :gen_udp.open(port, opts)
  end

  def handle_info({:udp, socket, host, port, bin}, socket) do
    msg = {:query, socket, host, port, bin}
    :poolboy.transaction(:dns_udp_pool, &GenServer.cast(&1, msg))
    {:noreply, socket}
  end

  def handle_info({:udp_socket, socket}, socket) do
    :inet.setopts(socket, active: 100)
    {:noreply, socket}
  end
end
