defmodule OCCI.Model do

  defmacro __using__(_opts) do
    quote do
      @entities []
    end
  end

  defmacro extension(name, import: extensions, do: body) do
    quote do
      defmodule unquote(:"#{name}") do
        unquote(body)
      end
    end
  end

  defmacro kind(name, extends: kind_ref, do: body) do
    quote do
      defmodule unquote(:"#{name}") do
        unquote(body)
      end
    end
  end

  defmacro mixin(name, applies: kinds, depends: mixins, do: body) do
    quote do
      defmodule unquote(:"#{name}") do
        unquote(body)
      end
    end
  end

  defmacro resource(id, kind: kind, mixins: mixins, state: init) do
    quote do
      res = :"#{unquote(kind)}".new(unquote(id))
      |> (&(Enum.reduce(unquote(mixins), &1, fn (mixin, acc) ->
                OCCI.Resource.add_mixin(acc, mixin)
              end))
      ).()
      |> (&(Enum.reduce(unquote(init), &1, fn ({k, v}, acc) ->
                put_in(acc, [k], v)
              end))
      ).()
      @store put_in(@store, unquote(id), res)
    end
  end
end
