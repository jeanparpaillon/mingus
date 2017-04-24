defmodule Mg.SSH.GitCmd do
  @moduledoc """
  Parse and exec git commands

  Original code from https://github.com/azukiapp/plowman
  """
  require Logger
  use GenServer
  alias Mg.SSH.Connection

  defstruct [:client, :port]

  @r_app_name Regex.compile!("^'\/*(?<app_name>[a-zA-Z0-9][a-zA-Z0-9@_-]*).git'$")
  @msg "Syntax is: git@...:<app>.git"


  def run(cmd, client) do
    case check_cmd(cmd) do
      {:ok, cmd, path} ->
        GenServer.start_link(__MODULE__, [cmd, path, client])
      err -> err
    end
  end

  def send(pid, data) do
    GenServer.cast(pid, {:data, data})
  end

  ###
  ### Callbacks
  ###
  def init([cmd, path, client]) do
    Process.flag(:trap_exit, true)
    pid = Port.open({:spawn, "#{cmd} #{path}"}, [:binary])
    {:ok, %Mg.SSH.GitCmd{ client: client, port: pid }}
  end

  def handle_cast({:data, data}, %Mg.SSH.GitCmd{ port: pid }=s) do
    # From SSH to Port
    Port.command(pid, data)
    {:noreply, s}
  end

  def handle_info({pid, {:data, data}}, %Mg.SSH.GitCmd{ port: pid, client: client }=s) do
    # From Port to SSH
    Connection.forward(client, data)
    {:noreply, s}
  end
  def handle_info({:EXIT, pid, reason}, %Mg.SSH.GitCmd{ port: pid, client: client }=s) do
    status = case reason do
               :normal -> 0
               _ -> 1
             end
    Connection.stop(client, status)
    {:stop, reason, s}
  end

  ###
  ### Private
  ###
  defp check_cmd(cmd) do
    case String.split(cmd, " ") do
      [git_cmd, path] when git_cmd == "git-receive-pack" or git_cmd == "git-upload-pack" ->
        check_path(path, git_cmd)
      _ ->
        {:error, :invalid_cmd, @msg}
    end
  end

  defp check_path(path, cmd) do
    case Regex.named_captures(@r_app_name, path) do
      %{ "app_name" => app_name }  ->
        check_app(cmd, app_name)
      _ ->
        {:error, :invalid_path, @msg}
    end
  end

  defp check_app(cmd, name) do
    # TODO !!!!
    # Serve real app, not mingus git dir !
    case find_git_dir(:code.priv_dir(:mingus)) do
      {:ok, dir} ->
        {:ok, cmd, dir}
      err -> err
    end
  end

  defp find_git_dir("/") do
    {:error, :unknown_app}
  end
  defp find_git_dir(dir) do
    if File.dir?(Path.join(dir, ".git")) do
      {:ok, dir}
    else
      find_git_dir(Path.expand(Path.join(dir, "..")))
    end
  end
end
