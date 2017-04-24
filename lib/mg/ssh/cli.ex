defmodule Mg.SSH.Cli do
  require Logger

  alias Mg.SSH.Connection
  alias Mg.SSH.GitCmd

  @behaviour :ssh_channel

  defstruct channel: nil, cm: nil, worker: nil

  ###
  ### Callbacks
  ###
  def init(_opts) do
    {:ok, %Mg.SSH.Cli{}}
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

  def handle_msg({:ssh_channel_up, channelId, connRef}, _) do
    {:ok, %Mg.SSH.Cli{ channel: channelId, cm: connRef }}
  end
  def handle_msg({:EXIT, pid, _reason}, %Mg.SSH.Cli{ worker: pid, channel: channelId }=s) do
    {:stop, channelId, s}
  end

  def handle_ssh_msg({:ssh_cm, cm, {:eof, channelId}}, %Mg.SSH.Cli{ cm: cm, channel: channelId }=s) do
    {:ok, s}
  end
  def handle_ssh_msg({:ssh_cm, cm, {:data, channelId, _, data}},
    %Mg.SSH.Cli{ cm: cm, channel: channelId, worker: pid }=s) do
    GitCmd.send(pid, data)
    {:ok, s}
  end
  def handle_ssh_msg({:ssh_cm, cm, {:exec, channelId, wantReply, cmd}}, %Mg.SSH.Cli{ cm: cm, channel: channelId }=s) do
    s = case GitCmd.run("#{cmd}", s) do
          {:error, _type, msg} ->
            Connection.reply_failure(cm, wantReply, channelId, "\n#{msg}\n\n")
            s
          {:ok, pid} ->
            %Mg.SSH.Cli{ s | worker: pid }
        end
    {:ok, s}
  end
  def handle_ssh_msg({:ssh_cm, cm, msg}, %Mg.SSH.Cli{ cm: cm, channel: channelId }=s) do
    ^channelId = elem(msg, 1)
    wantReply = try do; elem(msg, 2); rescue; _ -> false; end
    Connection.reply_failure(cm, wantReply, channelId)
    {:ok, s}
  end

  def code_change(_oldvsn, s, _extra) do
    {:ok, s}
  end
end
