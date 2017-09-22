defmodule Mix.Tasks.Ovh.Auth do
  @moduledoc """
  Mix task for creating auth token onto OVH API
  """
  alias Mg.Providers.Ovh

  @redirect "https://www.kbrw.fr"

  def run([]) do
    rules = case IO.gets("Do you want readonly or admin access (readonly|admin)\n") do
	            "admin\n" -> :admin
	            "readonly\n" -> :readonly
	          end
    {:ok, {url, ck}} = Ovh.__authorize__(rules, @redirect)

    IO.puts("Token created: #{ck}")
    IO.puts("Validate token going to: #{url}")
  end
end
