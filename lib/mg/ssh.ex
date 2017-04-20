defmodule Mg.SSH do
  import Supervisor.Spec
  require Logger

  alias Mg.Utils

  def start_link(opts) do
    {:ok, system_dir} = ensure_host_keys(Keyword.get(opts, :gen_host_key, true))
    ssh_opts = [
      id_string: 'Mingus Orchestrator',
      system_dir: system_dir,
      auth_methods: 'publickey',
      key_cb: Mg.SSH.Keys,
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

  ###
  ### Private
  ###
  defp ensure_host_keys(generate) do
    dir = Path.join(:code.priv_dir(:mingus), "keys")
    if generate do
      # Generate host key if not present
      :ok
    end
    {:ok, '#{dir}'}
  end
end
