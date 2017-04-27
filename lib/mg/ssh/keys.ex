defmodule Mg.SSH.Keys do
  require Record
  require Logger
  alias Mg.Store
  @behaviour :ssh_server_key_api
  @mixin_ssh :"http://schemas.ogf.org/occi/auth#ssh_user"

  def host_key(alg, opts) do
    host_keys = opts[:key_cb_private][:host_keys]
    case host_keys[alg] do
      nil -> {:error, :no_key}
      key -> {:ok, key}
    end
  end

  def is_auth_key(key, user, _opts) do
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

  @algorithms [
    :"ssh-rsa", :"ssh-dss", :"ecdsa-sha2-nistp256",
    :"ecdsa-sha2-nistp384", :"ecdsa-sha2-nistp521"
  ]
  def ensure_host_keys(generate) do
    dir = Path.join(:code.priv_dir(:mingus), "keys")
    @algorithms |> Enum.each(fn alg ->
      if not File.exists?(Path.join(dir, alg_to_basename(alg))) and generate do
        generate_host_key(dir, alg)
      end
    end)

    Path.wildcard("#{dir}/ssh_host_*_key") |> Enum.reduce(%{}, &read_host_key/2)
  end

  ###
  ### Private
  ###
  Record.defrecord RSAPrivateKey,
    Record.extract(:'RSAPrivateKey', from_lib: "public_key/include/public_key.hrl")
  Record.defrecord DSAPrivateKey,
    Record.extract(:'DSAPrivateKey', from_lib: "public_key/include/public_key.hrl")
  Record.defrecord ECPrivateKey,
    Record.extract(:'ECPrivateKey', from_lib: "public_key/include/public_key.hrl")

  # Defines from erlang 'public_key/include/public_key.hrl'
  # @todo should be extracted from generated HRL or, better, directly from ASN.1 source
  @secp256r1 {1, 2, 840, 10045, 3, 1, 7}
  @secp384r1 {1, 3, 132, 0, 34}
  @secp521r1 {1, 3, 132, 0, 35}

  defp read_host_key(path, acc) do
    bin = File.read!(path)
    case :public_key.pem_decode(bin) do
      [{_, _, :not_encrypted}=entry] ->
        key = :public_key.pem_entry_decode(entry)
        Logger.debug("Read SSH host key #{path}")
        Map.put(acc, key_to_alg(key), key)
      [entry] ->
        Logger.debug("Unsupported host key: #{inspect entry}")
        acc
      [] ->
        acc
    end
  end

  defp key_to_alg(key) when Record.is_record(key, :'RSAPrivateKey'),
    do: :"ssh-rsa"
  defp key_to_alg(key) when Record.is_record(key, :'DSAPrivateKey'),
    do: :"ssh-dss"
  defp key_to_alg({:'ECPrivateKey', _, _, {:'namedCurve', @secp256r1}, _}),
    do: :"ecdsa-sha2-nistp256"
  defp key_to_alg({:'ECPrivateKey', _, _, {:'namedCurve', @secp384r1}, _}),
    do: :"ecdsa-sha2-nistp384"
  defp key_to_alg({:'ECPrivateKey', _, _, {:'namedCurve', @secp521r1}, _}),
    do: :"ecdsa-sha2-nistp521"

  defp generate_host_key(dir, alg) do
    Logger.info("Generating SSH host key pair (#{alg})...")
    comment = Application.get_env(:mingus, :id, "mingus") <> "@mingus"
    type = alg_to_type(alg)
    path = Path.join(dir, alg_to_basename(alg))
    System.cmd("ssh-keygen", ["-t", type, "-C", comment, "-f", path, "-q"], stderr_to_stdout: true)
  end

  defp alg_to_type(:"ssh-rsa"), do: "rsa"
  defp alg_to_type(:"ssh-dss"), do: "dsa"
  defp alg_to_type(:"ecdsa-sha2-nistp256"), do: "ecdsa"
  defp alg_to_type(:"ecdsa-sha2-nistp384"), do: "ecdsa"
  defp alg_to_type(:"ecdsa-sha2-nistp521"), do: "ecdsa"

  defp alg_to_basename(:"ssh-rsa"), do: "ssh_host_rsa_key"
  defp alg_to_basename(:"ssh-dss"), do: "ssh_host_dsa_key"
  defp alg_to_basename(:"ecdsa-sha2-nistp256"), do: "ssh_host_ecdsa_key"
  defp alg_to_basename(:"ecdsa-sha2-nistp384"), do: "ssh_host_ecdsa_key"
  defp alg_to_basename(:"ecdsa-sha2-nistp521"), do: "ssh_host_ecdsa_key"
end
