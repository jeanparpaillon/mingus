defmodule Mg.Providers do
  @moduledoc """
  Supervise external data sources (providers)

  TODO: get provider infos from OCCI Store ?
  """
  import Supervisor.Spec

  def start_link(providers) do
    children = for {mod, name, args} <- providers do
      worker(mod, [name, args])
    end
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
