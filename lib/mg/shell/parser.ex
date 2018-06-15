defmodule Mg.Shell.Parser do
  @moduledoc """
  Parser for Mg Shell

  Grammar:

  command : 'help'
           | 'help' subject
           | 'quit'
           | subject action
           | subject action args
           ;

  subject : /* aliases categories */

  action : 'new'
          | 'get'
          | 'delete'
          | 'update'
          | 'help'
          | /* OCCI model defined action */
          ;

  args : arg ( args )* ;
  """
  alias OCCI.Model.Core
  alias OCCI.Store
  alias Mg.Shell.Complete
  alias Mg.Shell.Subject

  @spec eval(data :: String.t | charlist(), s :: map) :: :noreply | {:reply, String.t} | {:stop, msg :: String.t}
  def eval(str, s) when is_binary(str), do: eval(String.to_charlist(str), s)
  def eval(str, s) when is_list(str) do
    case :mg_shell_lexer.string(str) do
      {:ok, tokens, _} -> parse(tokens, s)
      e -> {:reply, format_error(e)}
    end
  end
  def eval({:error, :interrupted}, _), do: {:stop, "\nSee you soon...\n"}

  ###
  ### Priv
  ###
  defp parse([], _), do: :noreply
  defp parse([ {:atom, :help} ], _), do: help(nil)
  defp parse([ {:atom, :help}, {:atom, other} ], _), do: help(Subject.get(other))
  defp parse([ {:atom, :quit} | _ ], s), do: quit(s)
  defp parse([ {:atom, other} | rest ], s), do: category(rest, Subject.get(other), s)
  defp parse(_, _), do: {:reply, "Parse error...\n"}

  defp category([], {:invalid, cat}, _) do
    {:reply, """
    Invalid category: #{cat}
    """}
  end
  defp category([], cat, _), do: help(cat)
  defp category([ {:atom, :help} ], cat, _s), do: help(cat)
  defp category([ {:atom, :list} ], cat, s), do: list(cat, s)
  defp category([ {:atom, :new} ], cat, s), do: new(cat, s)
  defp category([ {:atom, :get}, {_, id} ], cat, s), do: get(cat, "#{id}", s)
  defp category(_, _cat, _s), do: {:reply, "Parse error...\n"}

  defp list(subject, _s) do
    category = Subject.category(subject)
    msg = """
    Instances of #{category.title()}:
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

  defp new(subject, _s) do
    kind = Map.get(subject, :kind)
    mixins = Map.get(subject, :mixins, [])

    IO.write("Creates new #{kind.title()}:\n")
    applicable_mixins = Mg.Model.applicable_mixins(kind)
    mixins = mixins ++ ask([
      name: :mixins,
      description: "Additional mixin",
      type: {OCCI.Types.Array, [type: {OCCI.Types.Mixin, Mg.Model}]},
      required: false
    ], fn b -> Complete.expand(b, applicable_mixins) end)
    specs = Mg.Model.specs([kind | mixins])

    try do
      attrs = Enum.reduce(specs, %{}, fn spec, acc ->
        case ask(spec) do
          nil -> acc
          value -> Map.put(acc, spec[:name], value)
        end
      end)

      entity = kind.new(attrs, mixins)
      entity = OCCI.Store.create(entity)
      {:reply, "Created: #{Core.Entity.id(entity)}\n"}
    rescue e in RuntimeError ->
        {:reply, e.message}
    end
  end

  defp get(_subject, id, _s) do
    case OCCI.Store.get(id) do
      nil -> {:reply, "NOT FOUND\n"}
      entity ->
        IO.write("#{inspect entity}\n")
        {:reply, "OK\n"}
    end
  end

  defp ask(spec, expand \\ nil) do
    expand = case expand do
               nil -> complete_fun(spec[:check])
               _ -> expand
             end
    prev_expand = set_expand(expand)

    desc = Keyword.get_lazy(spec, :description, fn ->
      "#{Keyword.get(:name, spec)} (#{Keyword.get(:type, spec)})"
    end)

    case spec[:check] do
      {OCCI.Types.Array, _} -> IO.write("Press ENTER to end list\n")
      _ -> nil
    end

    prompt_spec = []
    prompt_spec = case Keyword.get(spec, :default) do
                    nil -> prompt_spec
                    default -> [ "default: #{default}" | prompt_spec ]
                  end
    prompt_spec = if Keyword.get(spec, :required, false) do
      [ "required" | prompt_spec ]
    else
      prompt_spec
    end
    prompt_spec = case prompt_type(Keyword.get(spec, :check)) do
                    nil -> prompt_spec
                    type -> [ type | prompt_spec ]
                  end
    prompt = "#{desc}"
    prompt = if Enum.empty?(prompt_spec) do
      prompt
    else
      prompt <> " (" <> Enum.join(prompt_spec, ",") <> ")"
    end
    prompt = prompt <> "> "

    ret = case Keyword.get(spec, :check) do
            {OCCI.Types.Array, _} -> ask_array(prompt, [])
            _ -> ask2(prompt, Keyword.get(spec, :required, false))
          end

    _ = set_expand(prev_expand)

    ret
  end

  defp complete_fun({OCCI.Types.Enum, enum}), do: fn b -> Complete.expand(b, enum) end
  defp complete_fun({OCCI.Types.Array, [type: subtype]}), do: complete_fun(subtype)
  defp complete_fun(_), do: fn _ -> {:no, [], []} end

  defp prompt_type({OCCI.Types.URI, _}), do: "uri"
  defp prompt_type({OCCI.Types.Kind, _}), do: "kind"
  defp prompt_type({OCCI.Types.Mixin, _}), do: "mixin"
  defp prompt_type({OCCI.Types.Integer, _}), do: "integer"
  defp prompt_type({OCCI.Types.Float, _}), do: "float"
  defp prompt_type({OCCI.Types.Boolean, _}), do: "boolean"
  defp prompt_type({OCCI.Types.Enum, values}), do: "[" <> Enum.join(values, ",") <> "]"
  defp prompt_type({OCCI.Types.Array, [type: subtype]}), do: prompt_type(subtype)
  defp prompt_type({OCCI.Types.CIDR, _}), do: "CIDR"
  defp prompt_type(_), do: nil

  defp ask_array(prompt, acc) do
    case :io.get_line(prompt) do
      {:error, :interrupted} -> raise "Canceled...\n"
      data ->
        case data |> to_string |> String.trim do
          "" -> acc
          s -> ask_array(prompt, [ s | acc ])
        end
    end
  end

  defp ask2(prompt, required) do
    case :io.get_line(prompt) do
      {:error, :interrupted} -> raise "Canceled...\n"
      data ->
        case data |> to_string |> String.trim do
          "" -> if required, do: ask2(prompt, required), else: nil
          s -> s
        end
    end
  end

  defp help({:invalid, name}) do
    msg = """
    Invalid category: #{name}
    """
    {:reply, msg}
  end
  defp help(nil) do
    msg = """
    help            Display this help
    quit            Quit shell
    """
    msg = Enum.reduce(Subject.all(), msg, fn {name, subject}, acc ->
      f_name = :io_lib.format("~-16s", [name])
      acc <> "#{f_name}Manage #{subject.kind.title()}\n"
    end)
    {:reply, msg}
  end
  defp help(subject) do
    msg = Enum.reduce(Subject.actions(subject), "", fn
      {_, [desc1, desc2]}, acc -> [ acc, :io_lib.format("~-16s~s\n", [desc1, desc2]) ]
      {name, mod}, acc -> [ acc, :io_lib.format("~-16s~s\n", ["#{name} <id>", mod.title()]) ]
    end)
    {:reply, msg}
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
