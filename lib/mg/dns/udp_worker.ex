defmodule Mg.DNS.UDPWorker do
  @moduledoc """
  DNS server UDP wrapper
  """
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
