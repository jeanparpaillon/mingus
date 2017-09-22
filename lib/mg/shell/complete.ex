defmodule Mg.Shell.Complete do
  @moduledoc """
  Routines for expanding Mingus shell commands
  """
  alias OCCI.Store
  alias OCCI.Model.Core

  @keywords ["help", "quit"]
  @categories ["app", "user", "host"]

  @doc """
  Expand `before`. See erlang `edlin` module for semantic
  """
  @spec expand(charlist() | String.t, ctx :: any) :: {found :: :yes | :no, add :: charlist, matches :: list}
  def expand(before, keywords \\ nil) do
    before = before |> Enum.reverse
    {found, add, matches} = case keywords do
                              nil -> exp(tok(before, [], []), %{ keywords: [] })
                              _ -> retrieve(to_string(before), keywords)
                            end
    {found, add |> to_charlist, matches |> Enum.map(&to_charlist/1)}
  end

  ###
  ### Priv
  ###
  defp exp({:quote, _, _}, _s), do: {:no, "", []}
  defp exp({:word, [], cur}, _s), do: retrieve(to_string(cur), @keywords ++ @categories)
  defp exp({:word, ['quit'], _}, _s), do: {:no, "", []}
  defp exp({:word, ['help'], cur}, _s), do: retrieve(to_string(cur), @categories)
  defp exp({:word, [ category ], cur}, _s) do
    if category?(category) do
      retrieve(to_string(cur), ['new', 'list', 'delete', 'get', 'help'])
    else
      {:no, "", []}
    end
  end
  defp exp({:word, [ category, 'get' ], cur}, _), do: retrieve(to_string(cur),
        Store.lookup(category: lookup_category(category)) |> Enum.map(&(Core.Entity.get(&1, :id))))
  defp exp({:word, [ category, 'delete' ], cur}, _), do: retrieve(to_string(cur),
        Store.lookup(category: lookup_category(category)) |> Enum.map(&(Core.Entity.get(&1, :id))))
  defp exp({:word, _, _}, _), do: {:no, "", []}

  defp lookup_category('app'),    do: :"http://schemas.ogf.org/occi/platform#application"
  defp lookup_category('user'),   do: :"http://schemas.ogf.org/occi/auth#user"
  defp lookup_category('host'),   do: :"http://schemas.kbrw.fr/occi/infrastructure#host"

  defp category?(tok) do
    Enum.member?(@categories, "#{tok}")
  end

  defp retrieve(before, lexicon) do
    trie = Retrieval.new(lexicon |> Enum.map(&("#{&1}")))
    case Retrieval.prefix!(trie, before) do
      {nil, []} ->
        # No matching prefix
        {:no, "", []}
      {common, [_]} ->
        # Single match, complete the word + space and return no alternative
        {_, add} = String.split_at(common, String.length(before))
        {:yes, add <> " ", []}
      {common, matches} ->
        {_, add} = String.split_at(common, String.length(before))
        {:no, add, matches}
    end
  end

  # We're not inside a quote
  defp tok([], cur, acc), do: {:word, Enum.reverse(acc), Enum.reverse(cur)}
  # ' or ": Quote start
  defp tok([ ?\' | rest ], cur, acc), do: tok_quote(rest, ?\', [ ?\' | cur ], acc)
  defp tok([ ?\" | rest ], cur, acc), do: tok_quote(rest, ?\", [ ?\" | cur ], acc)
  # space: new word for the first one, ignore others
  defp tok([ ?\s | rest ], [], acc), do: tok(rest, [], acc)
  defp tok([ ?\s | rest ], cur, acc), do: tok(rest, [], [ Enum.reverse(cur) | acc ])
  # Else
  defp tok([ c | rest ], cur, acc), do: tok(rest, [ c | cur ], acc)

  # String end within a quote
  defp tok_quote([], _q, cur, acc), do: {:quote, Enum.reverse(acc), Enum.reverse(cur)}
  # End of quote
  defp tok_quote([ c | rest ], c, cur, acc), do: tok(rest, [ c | cur ], acc)
  # Else
  defp tok_quote([ c | rest ], q, cur, acc), do: tok_quote(rest, q, [ c | cur ], acc)
end
