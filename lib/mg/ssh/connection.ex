defmodule Mg.SSH.Connection do
  require Logger

  @moduledoc """
  Mostly wrapper around :ssh_connection
  """
  alias Mg.SSH.Cli

  def reply(%Cli{cm: cm, channel: channelId} = cli, status, wantReply, msg \\ nil) do
    if msg != nil, do: write_chars(cli, msg, 1)
    :ssh_connection.reply_request(cm, wantReply, status, channelId)
  end

  def forward(%Cli{} = cli, data) do
    write_chars(cli, data, 0)
  end

  def stop(%Mg.SSH.Cli{channel: channelId, cm: cm}, status) do
    :ssh_connection.exit_status(cm, channelId, status)
    :ssh_connection.close(cm, channelId)
  end

  def infos(connRef) do
    :ssh.connection_info(connRef, [:client_version, :server_version, :user, :peer, :sockname])
    |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  def write_chars(%Cli{channel: channelId, cm: cm}, chars, type \\ 0) do
    case has_chars(chars) do
      0 -> :ok
      _ -> :ssh_connection.send(cm, channelId, type, chars)
    end
  end

  def exit_status(%Cli{channel: channelId, cm: cm}, status) do
    :ssh_connection.exit_status(cm, channelId, status)
  end

  def send_eof(%Cli{channel: channelId, cm: cm}), do: :ssh_connection.send_eof(cm, channelId)

  ###
  ### Private
  ###
  defp has_chars([c | _]) when is_integer(c), do: true
  defp has_chars([h | t]) when is_list(h) or is_binary(h), do: has_chars(h) or has_chars(t)
  defp has_chars(<<_::size(8), _>>), do: true
  defp has_chars(_), do: false
end
