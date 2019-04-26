defmodule AkeneoApi.Connection do
    use GenServer
    require Logger

    def start_link(opts \\ [], name \\ __MODULE__) do
        client_id = opts[:client_id] || Application.get_env(:akeneo_api, :client_id)
        secret = opts[:secret] || Application.get_env(:akeneo_api, :secret)
        host = opts[:host] || Application.get_env(:akeneo_api, :host)
        token_url = opts[:host] || Application.get_env(:akeneo_api, :token_url)
        username = opts[:username] || Application.get_env(:akeneo_api, :username)
        password = opts[:password] || Application.get_env(:akeneo_api, :password)

        client = OAuth2.Client.new([
            strategy: AkeneoApi.OAuth2.Strategy,
            client_id: client_id,
            client_secret: secret,
            site: host,
            redirect_uri: "https://example.com/auth/callback",
            token_url: token_url,
            params: %{"username" => username, "password" => password}
        ])
        |> OAuth2.Client.put_serializer("application/json", Jason)
        |> OAuth2.Client.put_serializer("multipart/form-data", nil)

        state = %AkeneoApi.Connection.State{
            client_id: client_id,
            secret: secret,
            host: host,
            client: client
        }

        GenServer.start_link(__MODULE__, state, name: name)
    end

    @impl GenServer
    def init(state) do
        {:ok, state}
    end

    def get_token(name \\ __MODULE__) do
        GenServer.call(name, :get_token);
    end

    def refresh_token(name \\ __MODULE__) do
        GenServer.call(name, :refresh_token);
    end

    def get_state(name \\__MODULE__) do
        GenServer.call(name, :state);
    end

    @impl GenServer
    def handle_call(:state, _from, state) do
        {:reply, state, state}
    end

    @impl GenServer
    def handle_call(:get_token, _from, state) do
        client = state.client |> guarentee_token

        %OAuth2.Client{ token: token } = client

        {:reply, token, %{state | client: client}}
    end

    @impl GenServer
    def handle_call(:refresh_token, _from, state) do
        {:reply, :ok, %{state| client: state.client |> refresh_token!}}
    end

    @impl GenServer
    def handle_call(:get_client, _from, state) do
        {:reply, state.client, state}
    end

    @impl GenServer
    def handle_call({:set_client, client}, _from, state) do
        state = %{state | client: client}
        {:reply, :ok, state}
    end

    @impl GenServer
    def handle_call({:get, url}, _from, state) do
        client = state.client |> guarentee_token
        {:reply, client |> request_get(url), %{state | client: client}}
    end

    @impl GenServer
    def handle_call({:post, url, body, headers}, _from, state) do
        client = state.client |> guarentee_token
        {:reply, client |> request_post(url, body, headers), %{state | client: client}}
    end

    @impl GenServer
    def handle_call({:patch, url, body, headers}, _from, state) do
        client = state.client |> guarentee_token
        {:reply, client |> request_patch(url, body, headers), %{state | client: client}}
    end

    @impl GenServer
    def handle_call({:put, url, body, headers}, _from, state) do
        client = state.client |> guarentee_token
        {:reply, client |> request_put(url, body, headers), %{state | client: client}}
    end

    @impl GenServer
    def handle_call({:delete, url}, _from, state) do
        client = state.client |> guarentee_token
        {:reply, client |> request_delete(url), %{state | client: client}}
    end

    defp request_get(%OAuth2.Client{} = client, url) do
        OAuth2.Client.get(client, url) |> handle_response
    end

    defp request_post(%OAuth2.Client{} = client, url, body, headers) do
        OAuth2.Client.post(client, url, body, headers) |> handle_response
    end

    defp request_patch(%OAuth2.Client{} = client, url, body, headers) do
        OAuth2.Client.patch(client, url, body, headers) |> handle_response
    end

    defp request_put(%OAuth2.Client{} = client, url, body, headers) do
        OAuth2.Client.put(client, url, body, headers) |> handle_response
    end

    defp request_delete(%OAuth2.Client{} = client, url) do
        OAuth2.Client.delete(client, url) |> handle_response
    end

    defp handle_response(response) do
        case response do
            {:ok, %OAuth2.Response{body: body}} ->
                {:ok, body}
            {:error, %OAuth2.Response{status_code: 401, body: _body}} ->
                Logger.error("Unauthorized token")
                {:error, :unauthorized}
            {:error, %OAuth2.Error{reason: reason}} ->
                Logger.error("Error: #{inspect reason}")
                {:error, reason}
        end
    end

    @impl GenServer
    def handle_info(:refresh_token, state) do
        {:noreply, %{state| client: state.client |> refresh_token!}}
    end

    defp guarentee_token(client) do
        current_timestamp = :os.system_time(:seconds)

        case client.token do
            nil ->
                client |> OAuth2.Client.get_token! |> schedule_refresh

            %OAuth2.AccessToken{expires_at: expires_at} when expires_at <= current_timestamp ->
                client |> refresh_token! |> schedule_refresh

            %OAuth2.AccessToken{} -> client
        end
    end

    defp refresh_token!(%OAuth2.Client{} = client) do
        refresh_token = client.token.refresh_token

        refresh_client = OAuth2.Client.new(Map.to_list(%{
            client | strategy: OAuth2.Strategy.Refresh, params: %{"refresh_token" => refresh_token}
        }));

        OAuth2.Client.get_token!(refresh_client)
    end

    def schedule_refresh(client) do
        seconds = 1000 * max(0, client.token.expires_at - :os.system_time(:seconds) - 60) # 1 minute ahead
        Process.send_after(self(), :refresh_token, seconds)
        client
    end

    def get(url, name \\ __MODULE__) do
        GenServer.call(name, {:get, url})
    end

    def post(url, data, headers \\ [], name \\ __MODULE__) do
        GenServer.call(name, {:post, url, data, headers})
    end

    def patch(url, data, headers \\ [], name \\ __MODULE__) do
        GenServer.call(name, {:patch, url, data, headers})
    end

    def put(url, data, headers \\ [], name \\ __MODULE__) do
        GenServer.call(name, {:put, url, data, headers})
    end

    def delete(url, name \\ __MODULE__) do
        GenServer.call(name, {:delete, url})
    end

end
