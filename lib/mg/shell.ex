defmodule Mg.Shell do
  require Logger

  def start(user, ip) do
    spawn(fn -> loop(user, ip) end)
  end

  def loop(user, ip) do
    IO.write(prompt(user, ip))
    data = IO.read(:line)
    case eval(String.trim("#{data}")) do
      {:reply, ans} ->
        IO.write(ans <> "\n")
        loop(user, ip)
      :noreply ->
        loop(user, ip)
      {:stop, msg} ->
        IO.write(msg <> "\n")
    end
  end

  def data(pid, data) do
    to_worker(pid, data, "")
  end

  ###
  ### Private
  ###
  defp to_worker("", pid, acc) do
    send(pid, {self(), {:data, acc}})
    :ok
  end
  defp to_worker(<< 3 >> <> rest, pid, acc) do
    # 3 = CTRL-C
    send(pid, {self(), {:data, acc}})
    Process.exit(pid, :interrupt)
    to_worker(rest, pid, "")
  end
  defp to_worker(<< c :: size(8) >> <> rest, pid, acc), do: to_worker(rest, pid, acc <> << c  >>)

  defp eval("q"), do: cmd_exit()
  defp eval("Q"), do: cmd_exit()
  defp eval(other), do: {:reply, "Do you mean: #{other} ?"}

  defp cmd_exit, do: {:stop, "BYE"}

  defp prompt(user, {:undefined, {ip, _port}}), do: "#{user}@#{:inet.ntoa(ip)}> "
  defp prompt(user, {hostname, {_ip, _port}}), do: "#{user}@#{hostname}> "
end
