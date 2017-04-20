defmodule Mg do

  defmodule App do
    use Application
    def start(_type, _args) do
      Mg.Sup.start_link()
    end
  end

  defmodule Sup do
    import Supervisor.Spec

    def start_link do
      Supervisor.start_link([
        worker(Mg.Store, [Application.get_env(:mingus, :store)]),
	      worker(Mg.DNS, [Application.get_env(:mingus, :dns)])
      ], strategy: :one_for_one)
    end
  end
end
