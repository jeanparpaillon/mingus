defmodule Mix.Tasks.Ovh.Auth do
  def run([]) do
    rules = case IO.gets("Do you want readonly of admin access (readonly|admin)\n") do
	      "admin\n" -> :admin
	      "readonly\n" -> :readonly
	    end
    {:ok, %{url: url, ck: ck}} = Ovh.authorize(rules,
      "http://i.huffpost.com/gen/2262152/images/o-ORIGIN-OF-OK-facebook.jpg")
    IO.puts("OK ! use ck #{ck}, validate token at #{url}")
  end
end
