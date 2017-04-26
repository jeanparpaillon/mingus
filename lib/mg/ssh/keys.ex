defmodule Mg.SSH.Keys do
  require Logger
  alias Mg.Store
  @behaviour :ssh_server_key_api

  @kind_user :"http://schemas.ogf.org/occi/auth#user"
  @mixin_ssh :"http://schemas.ogf.org/occi/auth#ssh_user"

  def host_key(algorithm, opts) do
    :ssh_file.host_key(algorithm, opts)
  end

  def is_auth_key(key, user, opts) do
    case Store.get(category: @mixin_ssh, id: "#{user}") do
      [] -> false
      [user] ->
        case :public_key.ssh_decode(user[:attributes][:"occi.auth.ssh.pub_key"], :public_key) do
          [] -> false
          keys ->
            Enum.any?(keys, fn
              ({^key, _attrs}) -> true
              _ -> false
            end)
        end
    end
  end
end
