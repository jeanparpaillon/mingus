defmodule Mg do
  @moduledoc """
  Mingus entry point
  """
  use Application

  def start(_type, _args) do
    children = [
      # {OCCI.Store, Application.get_env(:occi, :backend)},
      # {Mg.SSH, Application.get_env(:mingus, :ssh)},
      {Mg.DNS, Application.get_env(:mingus, :dns)}
      # {Mg.Net, Application.get_env(:mingus, :net)}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
