defmodule Mg.SSH.Keys do
  @behaviour :ssh_server_key_api

  defdelegate host_key(algorithm, opts), to: :ssh_file

  defdelegate is_auth_key(key, user, opts), to: :ssh_file
end
