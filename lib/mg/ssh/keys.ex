defmodule Mg.SSH.Keys do
  require Record
  require Logger

  alias OCCI.Store
  alias Mg.Model.Auth

  # JP: Do not support deprecated key types, even if supported by backends
  # @type key_type :: :dsa | :ecdsa | :ed25519 | :rsa
  @type key_type :: :ed25519 | :rsa

  @behaviour :ssh_server_key_api

  @doc false
  def host_key(algorithm, options) do
    :ssh_file.host_key(algorithm, options)
  end

  @doc false
  def is_auth_key(key, user, _opts) do
    case Store.lookup(category: Auth.SshUser, "occi.auth.login": "#{user}") do
      [] -> false
      [user] ->
        authorized_key = user["occi.auth.ssh.pub_key"]
        case :public_key.ssh_decode(authorized_key, :auth_keys) do
          [] -> false
          decoded_keys ->
            Enum.any?(decoded_keys, fn {k, _info} -> k == key end)
        end
    end
  end

  @doc """
  Generate host keys
  """
  @spec gen_host_keys(Path.t, [ key_type ]) :: :ok
  def gen_host_keys(_dir, []), do: :ok
  def gen_host_keys(dir, [ type | others ]) do
    gen_host_keys(dir, others)
    pub = Path.join dir, "ssh_host_#{type}_key.pub"
    priv = Path.join dir, "ssh_host_#{type}_key"
    if (not File.exists?(pub)) or (not File.exists?(priv)) do
      _ = File.rm(pub)
      _ = File.rm(priv)
      :ok = gen_host_key(dir, type)
    end
    gen_host_keys(dir, others)
  end

  ###
  ### Priv
  ###

  # JP: should use crypto / public_key modules, if better documented ;)
  defp gen_host_key(dir, :ed25519) do
    basename = "ssh_host_ed25519_key"
    Logger.info("Generating SSH host key: #{basename}")
    {_, 0} = System.cmd("ssh-keygen",
      ["-t", "ed25519", "-N", "", "-f", Path.join(dir, basename)],
      stderr_to_stdout: true)
    :ok
  end
  defp gen_host_key(dir, :rsa) do
    basename = "ssh_host_rsa_key"
    Logger.info("Generating SSH host key: #{basename}")
    {_, 0} = System.cmd("ssh-keygen",
      ["-t", "rsa", "-N", "", "-f", Path.join(dir, basename)],
      stderr_to_stdout: true)
    :ok
  end
end
