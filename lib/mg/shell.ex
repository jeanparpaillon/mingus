defmodule Mg.Shell do
  require Logger

  def start(user, ip) do
    spawn(fn -> init(%{ user: user, ip: ip }) end)
  end

  def init(s) do
    Process.flag(:trap_exit, true)
    loop(s)
  end

  def loop(s) do
    IO.write(prompt(s.user, s.ip))
    data = IO.read(:line)
    case eval(String.trim("#{data}")) do
      {:reply, ans} ->
        IO.write(ans <> "\n")
        loop(s)
      :noreply ->
        loop(s)
      {:stop, msg} ->
        IO.write(msg <> "\n")
    end
  end

  def data(pid, data), do: to_worker(pid, data, [])

  ###
  ### Private
  ###
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

  defp eval("q"), do: cmd_exit()
  defp eval("Q"), do: cmd_exit()
  defp eval(other), do: {:reply, "Do you mean: #{other} ?"}

  defp cmd_exit, do: {:stop, "BYE"}

  defp prompt(user, {:undefined, {ip, _port}}), do: "#{user}@#{:inet.ntoa(ip)}> "
  defp prompt(user, {hostname, {_ip, _port}}), do: "#{user}@#{hostname}> "
end
