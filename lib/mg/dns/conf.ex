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
  def init(_opts) do
    {domain, _} =
      :erldns
      |> Application.get_env(:zone_delegates)
      |> List.first()

    %{domain: domain}
  end

  @doc """
  Returns config value
  """
  def get(key, default \\ nil) do
    Agent.get(__MODULE__, &Map.get(&1, key, default))
  end
end
