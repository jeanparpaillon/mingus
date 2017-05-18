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
        worker(OCCI.Store,     [Application.get_env(:mingus, :store)]),
        supervisor(Mg.SSH,     [Application.get_env(:mingus, :ssh)]),
	      supervisor(Mg.DNS,     [Application.get_env(:mingus, :dns)]),
        supervisor(Mg.Net,     [Application.get_env(:mingus, :net)])
      ], strategy: :one_for_one)
    end
  end
end
