defmodule Mg.Shell.Parser do
  @moduledoc """
  Parser for Mg Shell
  """
  alias OCCI.Model.Core
  alias OCCI.Store
  alias Mg.Shell.Complete

  @categories [
    app: :"http://schemas.ogf.org/occi/platform#application",
    user: :"http://schemas.ogf.org/occi/auth#user"
  ]

  @spec eval(data :: String.t | charlist(), s :: map) :: :noreply | {:reply, String.t} | {:stop, msg :: String.t}
  def eval(str, s) when is_binary(str), do: eval(String.to_charlist(str), s)
  def eval(str, s) when is_list(str) do
    case :mg_shell_lexer.string(str) do
      {:ok, tokens, _} -> parse(tokens, s)
      e -> {:reply, format_error(e)}
    end
  end

  def categories(), do: Enum.reduce(@categories, [], fn {key, id}, acc -> [ "#{key}", "#{id}" | acc ] end)

  ###
  ### Priv
  ###
  defp parse([], _), do: :noreply
  defp parse([ {:atom, :help} | _ ], _), do: help(nil)
  defp parse([ {:atom, :quit} | _ ], s), do: quit(s)
  defp parse([ {:atom, other} | rest ], s), do: category(rest, Keyword.get(@categories, other), s)
  defp parse(_, _), do: {:reply, "Parse error...\n"}

  defp category([], nil, _), do: {:reply, "Unknown category..."}
  defp category([], cat, _), do: help(cat)
  defp category([ {:atom, :list} ], cat, s), do: list(cat, s)
  defp category([ {:atom, :new} ], cat, s), do: new(cat, s)

  defp list(category, _s) do
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

  defp new(kind, s) do
    IO.write("Creates new #{Mg.Model.mod(kind).title}:\n")

    # TODO: example mixins, should get them from Model
    prev = set_expand(fn b -> Complete.expand(b, {:mixins, ["mixins0", "mixins1"]}) end)
    mixins = ask_mixins(kind, s, [])
    _ = set_expand(prev)

    str = Enum.join(mixins, ", ")
    IO.puts("MIXINS: #{str}")
    #entity = Mg.Model.new(kind, attrs)
    #OCCI.Store.create(entity)
    {:reply, "OK\n"}
  end

  defp ask_mixins(kind, s, acc) do
    case :io.get_line("Additional mixin (ENTER when finished) ?> ") do
      [?\n] -> acc
      data ->
        ask_mixins(kind, s, [ data |> to_string |> String.trim | acc ])
    end
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
    new             Create new instance of #{cat.title}
    """}
  end

  defp quit(%{ user: user }), do: {:stop, "Goodbye #{user}...\n"}

  defp format_error({:error, {_, _, {:illegal, c}}, pos}) do
    "Illegal caracter (pos #{pos}): '#{c}'"
  end
  defp format_error({:error, {_, _, desc}, pos}) do
    "Parse error (pos #{pos}): #{inspect desc}\n"
  end
  defp format_error(e) do
    "Error: #{inspect e}\n"
  end

  defp set_expand(fun) do
    opts = :io.getopts()
    prev = Keyword.get(opts, :expand_fun)
    :io.setopts([ {:expand_fun, fun} | opts ])
    prev
  end
end
