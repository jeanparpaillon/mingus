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

    with {:ok, banner} <- File.read(Path.join([:code.priv_dir(:mingus), "issue"])) do
      IO.write(banner)
    end

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

  @etx 3
  @eot 4

  defp to_worker(pid, '', acc) do
    send(pid, {self(), {:data, Enum.reverse(acc)}})
    :ok
  end
  defp to_worker(pid, [ @eot | _rest ], _acc) do
    Process.exit(pid, :interrupt)
  end
  defp to_worker(pid, [ @etx | _rest ], _acc) do
    send(pid, {self(), :eof})
  end
  defp to_worker(pid, [ c | rest ], acc), do: to_worker(pid, rest, [ c | acc ])
end
