defmodule Mg.SSH do
  import Supervisor.Spec
  require Record
  require Logger
  alias Mg.Store
  alias Mg.Utils
  alias Mg.SSH.Keys

  def start_link(opts) do
    host_keys = Keys.ensure_host_keys(Keyword.get(opts, :gen_host_key, true))
    system_dir = Path.join(:code.priv_dir(:mingus), "keys")
    ssh_opts = [
      id_string: 'Mingus Orchestrator',
      system_dir: '#{system_dir}',
      auth_methods: 'publickey',
      key_cb: {Mg.SSH.Keys, [host_keys: host_keys]},
      subsystems: [],
      ssh_cli: {Mg.SSH.Cli, []},
      user_interaction: false
    ]
    listeners = Keyword.get(opts, :listen, []) |> Enum.map(fn {addr, port} ->
      {_inet, a} = Utils.binding(addr)
      Logger.info("<SSH> Start listener on port #{port}")
      worker(:ssh, [a, port, ssh_opts], function: :daemon)
    end)

    Supervisor.start_link(listeners, strategy: :one_for_one)
  end
end
