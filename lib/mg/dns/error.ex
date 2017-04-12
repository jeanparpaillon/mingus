defmodule Mg.DNS.Error do
  defexception [:message]

  def exception(type), do: %Mg.DNS.Error{message: format(type)}

  defp format(:fmt),      do: "Error decoding message"
  defp format(_),         do: "Generic DNS error"
end
