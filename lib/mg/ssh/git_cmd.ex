defmodule Mg.SSH.GitCmd do
  @moduledoc """
  Parse and exec git commands

  Original code from https://github.com/azukiapp/plowman
  """
  require Logger
  use GenServer
  alias Mg.SSH.Connection
  alias OCCI.Store

  defstruct [:client, :port]

  @r_app_name Regex.compile!("^'\/*(?<app_name>[a-zA-Z0-9][a-zA-Z0-9@_-]*).git'$")
  @msg "Syntax is: git@...:<app>.git"

  @kind_application :"http://schemas.ogf.org/occi/platform#application"

  def run(cmd, client) do
    case check_cmd(cmd, client) do
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
  defp check_cmd(cmd, client) do
    case String.split(cmd, " ") do
      [git_cmd, path] when git_cmd == "git-receive-pack" or git_cmd == "git-upload-pack" ->
        check_path(path, git_cmd, client)
      _ ->
        {:error, :invalid_cmd, @msg}
    end
  end

  defp check_path(path, cmd, client) do
    case Regex.named_captures(@r_app_name, path) do
      %{ "app_name" => app_name }  ->
        check_app(cmd, app_name, client)
      _ ->
        {:error, :invalid_path, @msg}
    end
  end

  defp check_app(cmd, name, client) do
    case Store.lookup([kind: @kind_application, "occi.app.name": name], client.user) do
      {:ok, []} ->
        case cmd do
          # App do not exist
          "git-upload-pack" -> {:error, :unknown_app, @msg}
          "git-receive-pack" -> check_create_app(cmd, name, client)
        end
      {:ok, [app]} -> {:ok, cmd, find_git_dir(app)}
      {:error, err} -> {:error, err, @msg}
    end
  end

  def check_create_app(cmd, name, client) do
    attrs = [
      id: "apps/#{name}",
      "occi.app.name": name,
      "occi.core.summary": "Generated ..."
    ]
    case Store.create(@kind_application, attrs, client.user) do
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
