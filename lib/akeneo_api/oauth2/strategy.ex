defmodule AkeneoApi.OAuth2.Strategy do
    use OAuth2.Strategy

  @doc """
  Not used for this strategy.
  """
  def authorize_url(_client, _params) do
    raise OAuth2.Error, reason: "This strategy does not implement `authorize_url`."
  end

  defp auth_header(%{client_id: id, client_secret: secret} = client) do
    put_header(client, "Authorization", "Basic " <> Base.encode64(id <> ":" <> secret))
  end

  defp request_body(client) do
    client
    |> put_param(:client_id, client.client_id)
    |> put_param(:client_secret, client.client_secret)
  end

  @doc """
  Retrieve an access token given the specified End User username and password.
  """
  def get_token(client, params, headers) do
    {username, params} = Keyword.pop(params, :username, client.params["username"])
    {password, params} = Keyword.pop(params, :password, client.params["password"])

    unless username && password do
      raise OAuth2.Error, reason: "Missing required keys `username` and `password` for #{inspect __MODULE__}"
    end

    client
    |> put_param(:username, username)
    |> put_param(:password, password)
    |> put_param(:grant_type, "password")
    |> auth_header
    |> put_header("Content-Type", "application/json")
    |> merge_params(params)
    |> put_headers(headers)
  end
end