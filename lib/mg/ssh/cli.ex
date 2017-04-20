defmodule Mg.SSH.Cli do
  require Logger

  @behaviour :ssh_channel

  def init(_opts) do
    Logger.info("<SSH> opening channel")
    {:ok, %{}}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def handle_call(_msg, _from, s) do
    {:reply, :ok, s}
  end

  def handle_cast(_msg, s) do
    {:noreply, s}
  end

  def handle_msg(_msg, s) do
    {:ok, s}
  end

  def handle_ssh_msg(_msg, s) do
    {:ok, s}
  end
end
