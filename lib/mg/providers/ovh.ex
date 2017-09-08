defmodule Mg.Providers.Ovh do
  @app %{name: "mingus", ak: "D8aFgvJQi7DuMYic", as: "WNW0y5mPmwSdkf3wsGlbdfhpQHTq8Gjq"}
  @endpoint "https://eu.api.ovh.com/1.0"

  def authorize(:readonly,redirect_url) do
    authorize([%{method: "GET",path: "/*"}],redirect_url)
  end
  def authorize(:admin,redirect_url) do
    authorize(for(m <- ["GET", "POST", "PUT", "DELETE"], do:
		            %{method: m,path: "/*"}), redirect_url)
  end
  def authorize(rules, redirect_url) do
    with {:ok,{{_,200,_},_,body}} <-
	 :httpc.request(:post,
           {'#{@endpoint}/auth/credential',
	    [{'X-Ovh-Application','#{@app.ak}'}],
	    'application/json',
	    Poison.encode!(%{accessRules: rules, redirection: redirect_url})},[],[]),           {:ok,res} <- Poison.decode(body),
	   do: {:ok,%{url: res["validationUrl"],ck: res["consumerKey"]}}
  end

  # this token has been created by a `mix ovh.auth` command with readonly rights, unlimited expiration
  @ro_ck "dSLzTJnIMeebvfKequtrRMO9CoIxfCKh"

  def req(path,method \\ :get,ck \\ @ro_ck, body \\ nil) do
    url = "#{@endpoint}#{path}"
    ts = :erlang.system_time(:second)
    body = body && (body |> Enum.into(%{}) |> Poison.encode!(body))

    method_up = String.upcase("#{method}")
    sig = "$1$" <> Base.encode16(:crypto.hash(:sha,"#{@app.as}+#{ck}+#{method_up}+#{url}+#{body}+#{ts}"), case: :lower)
    headers = [
      {'X-Ovh-Application', '#{@app.ak}'},
      {'X-Ovh-Timestamp', '#{ts}'},
      {'X-Ovh-Signature', '#{sig}'},
      {'X-Ovh-Consumer', '#{ck}'}
    ]
    req = case method do
	    m when m in [:get,:delete] ->
	      {'#{url}',headers}
	    _->
	      {'#{url}', headers, 'application/json', body}
	  end
    {:ok, {{_, 200, _}, _, body_resp}} = :httpc.request(method, req, [], [])
    Poison.decode!(body_resp)
  end
end
