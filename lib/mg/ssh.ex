defmodule Mg.SSH do
  @moduledoc """
  SSH server

  Applications are managed in different modules:
  * Mg.Shell
  * Mg.SSH.GitCmd
  """
  import Supervisor.Spec
  require Record
  require Logger

  alias Mg.Utils

  @doc false
  def child_spec(opts) do
    %{ id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(opts) do
    system_dir = system_dir()
    gen_host_keys = Keyword.get(Application.get_env(:mingus, :ssh, []), :gen_host_key, [])
    :ok = Mg.SSH.Keys.gen_host_keys(system_dir, gen_host_keys)

    cb_opts = []

    ssh_opts = [
      id_string: 'Mingus Orchestrator',
      system_dir: system_dir,
      auth_methods: 'publickey',
      key_cb: {Mg.SSH.Keys, cb_opts},
      subsystems: [],
      preferred_algorithms: preferred_algorithms(),
      # shell: fn user, ip -> Mg.Shell.start(user, ip) end
      ssh_cli: {Mg.SSH.Cli, []}
    ]

    listeners =
      Keyword.get(opts, :listen, [])
      |> Enum.map(fn {addr, port} ->
        {_inet, a} = Utils.binding(addr)
        Logger.info("<SSH> Start listener on #{addr}:#{port}")
        worker(:ssh, [a, port, ssh_opts], function: :daemon)
      end)

    Supervisor.start_link(listeners, strategy: :one_for_one)
  end

  def system_dir() do
    cond do
      system_dir = Application.get_env(:mingus, :system_dir) ->
        to_charlist(system_dir)

      File.dir?("etc/ssh") ->
        to_charlist("/etc/ssh")

      true ->
        to_charlist(Path.join(:code.priv_dir(:mingus), "keys"))
    end
  end

  defp preferred_algorithms() do
    [
      public_key: [
        :"ecdsa-sha2-nistp256",
        :"ecdsa-sha2-nistp384",
        :"ecdsa-sha2-nistp521",
        :"ssh-rsa",
        :"ssh-dss"
        # Announced by erlang 20.x but not supported: see https://bugs.erlang.org/browse/ERL-531
        # :"rsa-sha2-256",
        # :"rsa-sha2-512",
      ]
    ]
  end
end
