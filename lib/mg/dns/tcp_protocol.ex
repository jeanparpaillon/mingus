defmodule Mg.DNS.TCPProtocol do
  @moduledoc """
  DNS TCP worker
  """
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
      {:ok, ""} ->
        :ok

      {:ok, data} ->
        case :inet.peername(socket) do
          {:ok, {from, port}} ->
            case GenServer.call(:dns, {:query, from, port, data}) do
              {:ok, ans} -> transport.send(socket, ans)
              {:error, _err} -> :ok
            end

          {:error, err} ->
            Logger.debug("<dns> tcp error: #{inspect(err)}")
            :ok
        end

      _ ->
        :ok = transport.close(socket)
    end
  end
end
