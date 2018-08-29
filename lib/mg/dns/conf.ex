defmodule Mg.DNS.Conf do
  @moduledoc """
  Store DNS resolver configuration
  """
  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {Agent, :start_link, [fn -> init(opts) end, [name: __MODULE__]]}
    }
  end

  @doc false
  def init(opts) do
    delegates =
      opts
      |> Keyword.get(:zones, [])
      |> Enum.reduce([], &domain_match/2)

    %{delegates: delegates}
  end

  @doc """
  Returns config value
  """
  def get(key, default \\ nil) do
    Agent.get(__MODULE__, &Map.get(&1, key, default))
  end

  ###
  ### Priv
  ###
  defp domain_match({domain, org_id}, acc) do
    safe_domain =
      domain
      |> String.downcase()
      |> String.replace(".", "\\.")

    regex = Regex.compile!("^(?<name>.*)\.(?<domain>" <> safe_domain <> ")$")
    [{regex, org_id} | acc]
  end
end
