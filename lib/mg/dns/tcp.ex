defmodule Mg.DNS.TCP do
  @moduledoc """
  DNS server TCP pool manager
  """
  require Logger

  def start_link(inet, addr, port) do
    opts = [:binary, {:active, 100}, {:reuseaddr, true}, {:ip, addr}, {:port, port}, inet]
    Logger.info("<DNS> listen on tcp://#{:inet.ntoa(addr)}:#{port}")
    :ranch.start_listener(:dns_tcp, 10, :ranch_tcp, opts, Mg.DNS.TCPProtocol, [])
  end
end
