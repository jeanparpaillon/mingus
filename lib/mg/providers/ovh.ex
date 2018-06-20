defmodule Mg.Providers.Ovh do
  @moduledoc """
  OVH API Access
  """
  use GenServer
  require Logger

  @app %{
    name: "mingus",
    ak: "8g4hG2o8IhLWKkNd",
    as: "7KQvwVLyhulfu2hcXE0IhSgadcblwq24"
  }
  @endpoint "https://eu.api.ovh.com/1.0"

  @api_servers "/dedicated/server"

  @doc false
  def start_link(name, args) do
    GenServer.start_link(__MODULE__, Keyword.get(args, :token), name: name)
  end

  @doc """
  Execute request on OVH API
  """
  def req(name, path, method \\ :get, body \\ nil),
    do: GenServer.call(name, {:req, path, method, body})

  @doc """
  Request authentication token
  """
  @spec get_token(name :: atom, rules :: :readonly | :admin, redirect_url :: String.t()) ::
          {:ok, {validation_url :: String.t(), customer_token :: String.t()}} | {:error, term}
  def get_token(name, rules, redirect_url) do
    GenServer.call(name, {:get_token, rules, redirect_url})
  end

  @doc """
  Launch authentication
  """
  @spec auth(name :: atom, token :: String.t()) :: :ok | :error
  def auth(name, token), do: GenServer.call(name, {:auth, token})

  ###
  ### GenServer callbacks
  ###
  @doc false
  def init(token) do
    Logger.info("Start OVH provider")
    resource = OCCI.Store.create(Mg.Model.Provider.new(%{id: "ovh"}, [Mg.Model.Provider.Ovh]))
    {_, s} = __auth__(token, %{auth: false, token: token, resource: resource})
    {:ok, s}
  end

  def handle_call({:req, _path, _method, _body}, _from, %{auth: false} = s) do
    {:reply, {:error, :unauthenticated}, s}
  end

  def handle_call({:req, path, method, body}, _from, %{token: token} = s) do
    {:reply, __req__(path, token, method, body), s}
  end

  def handle_call({:get_token, rules, redirect_url}, _from, s) do
    {:reply, __authorize__(rules, redirect_url), s}
  end

  def handle_call({:auth, token}, s) do
    {res, s} = __auth__(token, s)
    {:reply, res, s}
  end

  def handle_info(:inventory, %{token: token} = s) do
    with {:ok, {200, hosts}} <- __req__(@api_servers, token) do
      __inventory__(hosts, s)
    end

    {:noreply, s}
  end

  ###
  ### Private
  ###
  defp __inventory__([], _), do: :ok

  defp __inventory__([host | hosts], %{token: token} = s) do
    case __req__("#{@api_servers}/#{host}", token) do
      {:ok, {200, infos}} ->
        Logger.debug("HOST: #{host} => #{inspect(infos)}")
        :ok

      _ ->
        :ignore
    end

    __inventory__(hosts, s)
  end

  defp __auth__(token, %{token: token} = s) do
    case __req__("/me", token) do
      {:ok, {200, infos}} ->
        Logger.debug("<OVH >INFOS: #{inspect(infos)}")
        _ = Process.send_after(self(), :inventory, 0)
        {:ok, %{s | auth: true, token: token}}

      {:ok, {403, _}} ->
        Logger.debug("<OVH> Invalid credentials")
        {:error, %{s | auth: false}}

      err ->
        Logger.error("<OVH> Error: #{inspect(err)}")
        {:error, %{s | auth: false}}
    end
  end

  @doc """
  Creates authentication token.
  See: https://eu.api.ovh.com/g934.first_step_with_api
  """
  def __authorize__(:readonly, redirect_url) do
    __authorize__([%{method: "GET", path: "/*"}], redirect_url)
  end

  def __authorize__(:admin, redirect_url) do
    rules = for(m <- ["GET", "POST", "PUT", "DELETE"], do: %{method: m, path: "/*"})
    __authorize__(rules, redirect_url)
  end

  def __authorize__(rules, redirect_url) do
    url = '#{@endpoint}/auth/credential'
    hdrs = [{'X-Ovh-Application', '#{@app.ak}'}]
    body = Poison.encode!(%{accessRules: rules, redirection: redirect_url})
    ct = 'application/json'

    with {:ok, {{_, 200, _}, _, ans_body}} <-
           :httpc.request(:post, {url, hdrs, ct, body}, [], []),
         {:ok, res} <- Poison.decode(ans_body) do
      {:ok, {res["validationUrl"], res["consumerKey"]}}
    end
  end

  def __req__(path, ck, method \\ :get, body \\ nil) do
    url = "#{@endpoint}#{path}"
    ts = System.system_time(:second)
    body = body && body |> Enum.into(%{}) |> Poison.encode!(body)

    method_up = String.upcase("#{method}")

    sig =
      "$1$" <>
        Base.encode16(
          :crypto.hash(:sha, "#{@app.as}+#{ck}+#{method_up}+#{url}+#{body}+#{ts}"),
          case: :lower
        )

    headers = [
      {'X-Ovh-Application', '#{@app.ak}'},
      {'X-Ovh-Timestamp', '#{ts}'},
      {'X-Ovh-Signature', '#{sig}'},
      {'X-Ovh-Consumer', '#{ck}'}
    ]

    req =
      case method do
        m when m in [:get, :delete] ->
          {'#{url}', headers}

        _ ->
          {'#{url}', headers, 'application/json', body}
      end

    case :httpc.request(method, req, [], []) do
      {:ok, {{_, code, _}, _, body_resp}} -> {:ok, {code, Poison.decode!(body_resp)}}
      {:error, _} = err -> err
    end
  end
end
