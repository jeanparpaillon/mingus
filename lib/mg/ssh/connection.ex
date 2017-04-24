defmodule Mg.SSH.Connection do

  def reply_failure(cm, wantReply, channel, msg \\ nil) do
    if msg != nil, do: write_chars(cm, channel, msg, 1)
    :ssh_connection.reply_request(cm, wantReply, :failure, channel)
  end

  def forward(%Mg.SSH.Cli{ channel: channel, cm: cm }, data) do
    write_chars(cm, channel, data, 0)
  end

  def stop(%Mg.SSH.Cli{ channel: channel, cm: cm }, status) do
    :ssh_connection.exit_status(cm, channel, status)
    :ssh_connection.close(cm, channel)
  end

  ###
  ### Private
  ###
  defp write_chars(cm, channel, chars, type) do
    case :erlang.iolist_size(chars) do
      0 -> :ok
      _ -> :ssh_connection.send(cm, channel, type, chars)
    end
  end
end
