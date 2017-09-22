defmodule Mg.Shell.Parser do
  @moduledoc """
  Parser for Mg Shell
  """
  alias OCCI.Model.Core
  alias OCCI.Store
  alias Mg.Shell.Complete

  @categories [
    app: {:"http://schemas.ogf.org/occi/platform#application", []},
    user: {:"http://schemas.ogf.org/occi/auth#user", []},
    host: {:"http://schemas.ogf.org/occi/infrastructure#compute",
           [:"http://schemas.kbrw.fr/occi/infrastructure#host"]}
  ]

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
  defp parse([ {:atom, :help}, {:atom, other} ], _), do: help(lookup_category(other))
  defp parse([ {:atom, :quit} | _ ], s), do: quit(s)
  defp parse([ {:atom, other} | rest ], s), do: category(rest, Keyword.get(@categories, other, {:invalid, other}), s)
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

  defp lookup_category(:app),  do: :"http://schemas.ogf.org/occi/platform#application"
  defp lookup_category(:user), do: :"http://schemas.ogf.org/occi/auth#user"
  defp lookup_category(:host), do: :"http://schemas.kbrw.fr/occi/infrastructure#host"
  defp lookup_category(cat),   do: {:invalid, cat}

  defp list(category, _s) do
    msg = """
    Instances of #{Mg.Model.title(category)}:
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

  defp new({kind, mixins}, _s) do
    IO.write("Creates new #{Mg.Model.title(kind)}:\n")
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

      entity = Mg.Model.new(kind, attrs, mixins)
      OCCI.Store.create(entity)
      {:reply, "OK\n"}
    rescue e in RuntimeError ->
        {:reply, e.message}
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

  defp help(nil) do
    msg = """
    help            Display this help
    quit            Quit shell
    """
    msg = Enum.reduce(@categories, msg, fn {name, catId}, acc ->
      f_name = :io_lib.format("~-16s", [name])
      acc <> "#{f_name}Manage #{Mg.Model.title(catId)}\n"
    end)
    {:reply, msg}
  end
  defp help({:invalid, cat}) do
    {:reply, """
    Invalid category: #{cat}
    """}
  end
  defp help(category) do
    title = Mg.Model.title(category)
    {:reply, """
    help            Display this help
    list            List all #{title}
    new             Create new #{title}
    delete <id>     Delete #{title}
    get <id>        Display #{title}
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
