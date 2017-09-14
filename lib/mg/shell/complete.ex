defmodule Mg.Shell.Complete do
  @moduledoc """
  Routines for expanding Mingus shell commands
  """
  alias Mg.Shell.Parser

  @keywords ["help", "quit"]

  @doc """
  Expand `before`. See erlang `edlin` module for semantic
  """
  @spec expand(charlist() | String.t, ctx :: any) :: {found :: :yes | :no, add :: charlist, matches :: list}
  def expand(before, ctx \\ nil) do
    str = to_string(before |> Enum.reverse)
    {found, add, matches} = exp(str, lexicon(ctx))
    {found, add |> to_charlist, matches |> Enum.map(&to_charlist/1)}
  end

  ###
  ### Priv
  ###
  defp exp(before, trie) do
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

  defp lexicon(nil), do: Retrieval.new(@keywords ++ Parser.categories())
  defp lexicon(possible), do: Retrieval.new(possible |> Enum.map(&("#{&1}")))
end
