defmodule Mg.SSH.GitCmd do
  @moduledoc """
  Parse and exec git commands

  Original code from https://github.com/azukiapp/plowman
  """
  require Logger
  use GenServer
  alias Mg.SSH.{GitCmd, Cli, Connection}
  alias OCCI.Store
  alias Mg.Model.Platform

  defstruct [:port, :cli, :cli_pid]

  @r_app_name Regex.compile!("^'\/*(?<app_name>[a-zA-Z0-9][a-zA-Z0-9@_-]*).git'$")
  @msg "Syntax is: git@...:<app>.git"

  def run(cmd, cli) do
    case check_cmd(cmd, cli) do
      {:ok, cmd, path} ->
        case GenServer.start(__MODULE__, [cmd, path, cli, self()]) do
          {:ok, pid} -> {:success, %Cli{cli | worker: pid, worker_mod: __MODULE__}}
          {:error, _err} -> {:failure, @msg, cli}
        end

      {:error, _, msg} ->
        {:failure, msg, cli}
    end
  end

  def data(pid, data), do: send(pid, {self(), {:data, data}})

  ###
  ### Callbacks
  ###
  def init([cmd, path, cli, cli_pid]) do
    Process.flag(:trap_exit, true)
    pid = Port.open({:spawn, "#{cmd} #{path}"}, [:binary])
    {:ok, %GitCmd{cli: cli, cli_pid: cli_pid, port: pid}}
  end

  def handle_info({cli, {:data, data}}, %GitCmd{port: port, cli_pid: cli} = s) do
    # From SSH to Port
    Port.command(port, data)
    {:noreply, s}
  end

  def handle_info({port, {:data, data}}, %GitCmd{port: port, cli: cli} = s) do
    # From Port to SSH
    Connection.forward(cli, data)
    {:noreply, s}
  end

  def handle_info({:EXIT, port, reason}, %GitCmd{port: port, cli: cli} = s) do
    status =
      case reason do
        :normal -> 0
        _ -> 1
      end

    Connection.stop(cli, status)
    {:stop, reason, s}
  end

  def handle_info({:EXIT, cli_pid, reason}, %GitCmd{cli_pid: cli_pid} = s) do
    Logger.debug(fn -> "CLI end: #{inspect(reason)}" end)
    {:noreply, s}
  end

  ###
  ### Private
  ###
  defp check_cmd(cmd, cli) do
    case String.split(cmd, " ") do
      [git_cmd, path] when git_cmd == "git-receive-pack" or git_cmd == "git-upload-pack" ->
        check_path(path, git_cmd, cli)

      _ ->
        {:error, :invalid_cmd, @msg}
    end
  end

  defp check_path(path, cmd, cli) do
    case Regex.named_captures(@r_app_name, path) do
      %{"app_name" => app_name} ->
        check_app(cmd, app_name, cli)

      _ ->
        {:error, :invalid_path, @msg}
    end
  end

  defp check_app(cmd, name, cli) do
    case Store.lookup(kind: Platform.Application, "occi.app.name": name) do
      [] ->
        case cmd do
          # App do not exist
          "git-upload-pack" ->
            {:error, :unknown_app, @msg}

          "git-receive-pack" ->
            check_create_app(cmd, name, cli)
        end

      [app] ->
        {:ok, cmd, find_git_dir(app)}
    end
  end

  def check_create_app(cmd, name, cli) do
    attrs = [
      id: "apps/#{name}",
      "occi.app.name": name,
      "occi.core.summary": "Generated ..."
    ]

    app = Platform.Application.new(attrs)

    case Store.create(app, cli.user) do
      {:ok, app} -> {:ok, cmd, find_git_dir(app)}
      {:error, err} -> {:error, err, @msg}
    end
  end

  defp find_git_dir(app) do
    app_name = app.attributes[:"occi.app.name"]
    dir = Path.join([:code.priv_dir(:mingus), "git", "#{app_name}.git"])
    # WARNING: git dir should be created when adding an app ?
    if not File.exists?(dir) do
      System.cmd("git", ["init", "--bare", dir])
    end

    dir
  end
end
