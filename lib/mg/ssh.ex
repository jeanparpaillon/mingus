defmodule Mg.SSH do
  import Supervisor.Spec
  require Logger
  alias Mg.Store
  alias Mg.Utils
  alias Mg.SSH.Keys

  def start_link(opts) do
    host_keys = ensure_host_keys(Keyword.get(opts, :gen_host_key, true))
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

  ###
  ### Private
  ###
  defp ensure_host_keys(generate) do
    dir = Path.join(:code.priv_dir(:mingus), "keys")
    if Path.wildcard("#{dir}/ssh_host_*_key") == [] and generate do
      generate_host_keys(dir)
    end

    Path.wildcard("#{dir}/ssh_host_*_key") |> Enum.reduce(%{}, fn path, acc ->
      bin = File.read!(path)
      :public_key.pem_decode(bin) |> Enum.reduce(acc, fn
        ({:"RSAPrivateKey", _, :not_encrypted}=key, acc2) -> Map.put(acc2, :"ssh-rsa", key)
        ({:"DSAPrivateKey", _, :not_encrypted}=key, acc2) -> Map.put(acc2, :"ssh-dss", key)
        # Don't know how to treat ec keys: ecdsa-sha2-nistp{256,384,521} ???
        ({:"ECPrivateKey", _, :not_encrypted}=key, acc2) -> acc2
        (key, acc2) -> acc2
      end)
    end)
  end

  defp generate_host_keys(dir) do
    ["rsa", "dsa", "ecdsa", "ed25519"] |> Enum.each(fn type ->
      path = Path.join([dir, "ssh_host_#{type}_key"])
      if not File.exists?(path) do
        Logger.info("Generating SSH host key pair (#{type})...")
        comment = Application.get_env(:mingus, :id, "mingus") <> "@mingus"
        System.cmd("ssh-keygen", ["-t", type, "-C", comment, "-f", path, "-q"], stderr_to_stdout: true)
      end
    end)
  end
end
