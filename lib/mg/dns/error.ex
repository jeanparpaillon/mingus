defmodule Mg.DNS.Error do
  @type t :: %__MODULE__{message: String.t()}
  defexception [:message]

  def exception(type), do: %__MODULE__{message: format(type)}

  @spec format(any) :: String.t()
  defp format(:fmt), do: "Error decoding message"
  defp format(_), do: "Generic DNS error"
end
