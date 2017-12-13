defmodule Mg.SSH.Keys do
  require Record
  require Logger

  alias OCCI.Store
  alias Mg.Model.Auth

  @behaviour :ssh_server_key_api

  def host_key(algorithm, options) do
    :ssh_file.host_key(algorithm, options)
  end

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
end
