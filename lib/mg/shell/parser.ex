defmodule Mg.Shell.Parser do
  @moduledoc """
  Parser for Mg Shell
  """
  alias OCCI.Model.Core
  alias OCCI.Store

  @spec eval(data :: String.t | charlist(), s :: map) :: :noreply | {:reply, String.t} | {:stop, msg :: String.t}
  def eval(str, s) when is_binary(str), do: eval(String.to_charlist(str), s)
  def eval(str, _s) when is_list(str) do
    case :mg_shell_lexer.string(str) do
      {:ok, tokens, _} -> parse(tokens)
      e -> {:reply, format_error(e)}
    end
  end

  ###
  ### Priv
  ###
  @categories [
    app: :"http://schemas.ogf.org/occi/platform#application",
    user: :"http://schemas.ogf.org/occi/auth#user"
  ]

  defp parse([]), do: :noreply
  defp parse([ {:atom, :help} | _ ]), do: help(nil)
  defp parse([ {:atom, :quit} | _ ]), do: quit()
  defp parse([ {:atom, other} | rest ]), do: category(rest, Keyword.get(@categories, other))
  defp parse(_), do: {:reply, "Parse error...\n"}

  defp category([], nil), do: {:reply, "Unknown category..."}
  defp category([], cat), do: help(cat)
  defp category([ {:atom, :list} ], cat), do: list(cat)

  defp list(category) do
    mod = Mg.Model.mod(category)
    msg = """
    Instances of #{mod.title}:
    """
    msg = Enum.reduce(Store.lookup(category: category), msg, fn entity, acc ->
      id = :io_lib.format("~-40s", [Core.Entity.get(entity, :id)])
      desc = case Core.Entity.get(entity, :title) do
               nil -> ""
               title -> "(#{title})"
             end
      acc <> " * #{id} #{desc}\n"
    end)
    {:reply, msg}
  end

  defp help(nil) do
    msg = """
    help            Display this help
    quit            Quit shell
    """
    msg = Enum.reduce(@categories, msg, fn {name, catId}, acc ->
      mod = Mg.Model.mod(catId)
      f_name = :io_lib.format("~-16s", [name])
      acc <> "#{f_name}Manage #{mod.title}\n"
    end)
    {:reply, msg}
  end
  defp help(category) do
    cat = Mg.Model.mod(category)
    {:reply, """
    help            Display this help
    list            List all instances of #{cat.title}
    """}
  end

  defp quit, do: {:stop, "Goodbye...\n"}

  defp format_error({:error, {_, _, {:illegal, c}}, pos}) do
    "Illegal caracter (pos #{pos}): '#{c}'"
  end
  defp format_error({:error, {_, _, desc}, pos}) do
    "Parse error (pos #{pos}): #{inspect desc}\n"
  end
  defp format_error(e) do
    "Error: #{inspect e}\n"
  end
end
