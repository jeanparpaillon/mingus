defmodule Mg.Project do
  @moduledoc """
  Handles Mingus projects.

  A Mingus project is defined by calling `use Mg.Project` in a module,
  placed in `play.exs`.
  """

  defmacro __using__(_opts) do
    quote do
      @after_compile Mg.Project
    end
  end

  @doc false
  def __after_compile__(_env, _data) do
    :ok
  end
end
