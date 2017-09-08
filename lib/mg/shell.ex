defmodule Mg.Shell do
  @moduledoc """
  Mingus shell: use edlin driver for completion, history...
  """
  require Logger
  alias Mg.Shell.Parser

  def start_group(user, ip) do
    opts = [
      echo: true,
      expand_fun: fn b -> Mg.Shell.Complete.expand(b) end
    ]
    :group.start(self(), fn -> start(user, ip) end, opts)
  end

  def start(user, ip) do
    spawn(fn -> init(%{ user: user, ip: ip }) end)
  end

  def init(s) do
    Process.flag(:trap_exit, true)
    loop(s)
  end

  def loop(s) do
    case Parser.eval(:io.get_line(prompt(s.user, s.ip)), s) do
      {:reply, ans} ->
        IO.write(ans)
        loop(s)
      :noreply ->
        loop(s)
      {:stop, msg} ->
        IO.write(msg)
    end
  end

  def data(pid, data), do: to_worker(pid, data, [])

  ###
  ### Private
  ###
  defp prompt(user, {:undefined, {ip, _port}}), do: "#{user}@#{:inet.ntoa(ip)}> "
  defp prompt(user, {hostname, {_ip, _port}}), do: "#{user}@#{hostname}> "

  @ctrl_c 3

  defp to_worker(pid, '', acc) do
    send(pid, {self(), {:data, Enum.reverse(acc)}})
    :ok
  end
  defp to_worker(pid, [ @ctrl_c | rest ], acc) do
    send(pid, {self(), {:data, Enum.reverse(acc)}})
    Process.exit(pid, :interrupt)
    to_worker(pid, rest, [])
  end
  defp to_worker(pid, [ c | rest ], acc), do: to_worker(pid, rest, [ c | acc ])
end
