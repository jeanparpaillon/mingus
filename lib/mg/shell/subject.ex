defmodule Mg.Shell.Subject do
  @moduledoc """
  Handle Mingus shell subjects.

  Subjects are mostly OCCI categories aliases
  """

  @actions [
    list: ["list", "List all instances"],
    get: ["get <id>", "Display instance"],
    help: ["help", "Display this help"]
  ]
  @subjects %{
    app: %{
      kind: Mg.Model.Platform.Application,
      actions: @actions
    },
    user: %{
      kind: Mg.Model.Auth.User,
      actions: [
        {:new, ["new", "Creates new instance"]},
        {:delete, ["delete <id>", "Delete instance"]}
        | @actions
      ]
    },
    host: %{
      kind: OCCI.Model.Infrastructure.Compute,
      mixins: [Mg.Model.Infrastructure.Host],
      actions: @actions
    },
    provider: %{
      kind: Mg.Model.Provider,
      mixins: [Mg.Model.Provider.Ovh],
      actions: @actions
    }
  }

  def get(name) when is_list(name) or is_binary(name), do: get(:"#{name}")
  def get(name), do: Map.get(@subjects, name, {:invalid, name})

  def all, do: @subjects

  def names, do: Map.keys(@subjects) |> Enum.map(&"#{&1}")

  def category(subject) when is_map(subject) do
    case subject[:mixins] do
      nil -> subject[:kind]
      [mixin | _] -> mixin
    end
  end

  def category(name), do: get(name) |> category()

  def valid?(name), do: Map.keys(@subjects) |> Enum.member?(:"#{name}")

  def actions(subject) when is_map(subject) do
    Map.get(subject, :actions, []) ++
      Enum.map(
        Mg.Model.actions([Map.get(subject, :kind) | Map.get(subject, :mixins, [])]),
        fn {name, mod} ->
          {name, mod}
        end
      )
  end

  def actions(name), do: get(name) |> actions()
end
