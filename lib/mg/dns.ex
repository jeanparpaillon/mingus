defmodule Mg.DNS do
  @moduledoc """
  Supervise DNS listeners
  """
  require Logger

  alias Mg.DNS

  @doc false
  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}, type: :supervisor}
  end

  def start_link(opts) do
    children = [
      {DNS.Conf, opts}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
