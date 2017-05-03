defmodule Mg.Store do
  use GenServer
  require Logger

  @kind_resource :"http://schemas.ogf.org/occi/core#resource"
  @kind_link :"http://schemas.ogf.org/occi/core#link"

  def start_link(src) do
    path = case src do
             {:priv_dir, path} ->
               Path.join(:code.priv_dir(:mingus), path)
             p when is_binary(p) ->
               p
           end
    data = File.read!(path) |> Poison.decode!(keys: :atoms) |> parse
    Agent.start_link(fn -> data end, name: __MODULE__)
  end

  @doc """
  Create new entity
  TODO: plug to erlang-occi for type checking etc
  TODO: handle user
  """
  def create(kind, attrs, _user) do
    init = %{
      kind: kind,
      parent: @kind_resource,
      attributes: %{}
    }
    entity = Enum.reduce(attrs, init, fn
      ({:id, id}, acc) -> Map.put(acc, :id, id)
      ({:kind, _}, acc) -> acc
      ({:parent, parent}, acc) -> Map.put(acc, :parent, parent)
      ({:mixins, mixins}, acc) -> Map.put(acc, :mixins, mixins)
      ({:source, source}, acc) -> Map.put(acc, :source, source)
      ({:target, target}, acc) -> Map.put(acc, :target, target)
      ({key, value}, acc) -> %{ acc | attributes: Map.put(acc.attributes, key, value) }
    end)
    {:ok, entity}
  end

  @doc """
  Fetch entity from store with given args as filters
  """
  def get(args) do
    Logger.debug("Store.get(#{inspect args})")
    Agent.get(__MODULE__, &(&1))
    |> Enum.filter(fn ({_, item}) -> match(item, args) end)
    |> Enum.map(fn ({_, entity}) -> entity end)
  end

  @doc """
  Fetch entity from store with given args as filters, and check authorization
  TODO: really check authorization
  """
  def get(args, _user) do
    {:ok, get(args)}
  end

  @doc """
  Returns given filtered resource links
  If entity is a link, returns []
  """
  def links(entity, args \\ []) do
    Logger.debug("Store.links(#{inspect entity}, #{inspect args})")
    case entity[:parent] do
      @kind_resource ->
        links = entity[:links] || []
        Enum.map(links, fn (link) -> get([ {:id, link} | args ]) end) |> List.flatten
      @kind_link ->
        []
    end
  end

  ###
  ### Private
  ###
  defp match(item, {:not, filters}) do
    not match(item, filters)
  end
  defp match(item, {:or, filters}) when is_list(filters) do
    Enum.any?(filters, &(match(item, &1)))
  end
  defp match(item, {:and, filters}) when is_list(filters) do
    Enum.all?(filters, &(match(item, &1)))
  end
  defp match(item, filters) when is_list(filters) do
    Enum.all?(filters, &(match(item, &1)))
  end
  defp match(item, {:category, category}) do
    match(item, {:or, [parent: category, kind: category, mixin: category]})
  end
  defp match(item, {:kind, value}), do: item[:kind] == value
  defp match(item, {:parent, value}), do: item[:parent] == value
  defp match(item, {:mixin, value}) do
    value in (item[:mixins] || [])
  end
  defp match(item, {:id, value}), do: item[:id] == value
  defp match(item, {:source, value}), do: item[:source][:location] == value
  defp match(item, {:target, value}), do: item[:target][:location] == value
  defp match(item, {key, value}) when is_atom(key) do
    item[:attributes][key] == value
  end
  defp match(item, {keys, value}) when is_list(keys) do
    get_in(item[:attributes], keys) == value
  end

  defp parse(data) do
    Enum.reduce(data, %{}, fn (item, store) ->
      Enum.reduce(item, %{}, fn
        ({:kind, kind}, acc) -> Map.put(acc, :kind, :"#{kind}")
        ({:parent, parent}, acc) -> Map.put(acc, :parent, :"#{parent}")
        ({:mixins, mixins}, acc) -> Map.put(acc, :mixins, Enum.map(mixins, &(:"#{&1}")))
        ({k, v}, acc) -> Map.put(acc, k, v)
      end) |> (&(Map.put(store, &1.id, &1))).()
    end)
  end
end
