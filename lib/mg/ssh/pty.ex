defmodule Mg.SSH.Pty do
  @moduledoc """
  Structure for PTY
  """
  defstruct term: "", width: 80, height: 25, pixelWidth: 1024, pixelHeight: 768, modes: ""
end
