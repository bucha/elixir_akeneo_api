defmodule AkeneoApiTest do
  use ExUnit.Case
  doctest AkeneoApi

  test "receives bearer token" do
    token = AkeneoApi.Connection.get_token()
    assert %OAuth2.AccessToken{ token_type: "Bearer" } = token
  end

  test "receives bearer token only one" do
    token = AkeneoApi.Connection.get_token()
    token2 = AkeneoApi.Connection.get_token()
    assert token.access_token == token2.access_token
  end

  test "refresh retrieves new token" do
    token = AkeneoApi.Connection.get_token()
    AkeneoApi.Connection.refresh_token()
    token2 = AkeneoApi.Connection.get_token()
    assert token.access_token != token2.access_token
  end

  test "refresh upon token expiry" do
    token = AkeneoApi.Connection.get_token()

    expiredToken = %{token | expires_at: 0}

    client = GenServer.call(AkeneoApi.Connection, :get_client)

    GenServer.call(AkeneoApi.Connection, {:set_client, %{client | token: expiredToken}})

    token2 = AkeneoApi.Connection.get_token()
    assert token.access_token != token2.access_token
  end

  test "automatically refreshes token" do
    token = AkeneoApi.Connection.get_token()

    expiredToken = %{token | expires_at: :os.system_time(:seconds) + 5}

    client = GenServer.call(AkeneoApi.Connection, :get_client)

    GenServer.call(AkeneoApi.Connection, {:set_client, %{client | token: expiredToken}})

    :timer.sleep(6000);

    token2 = AkeneoApi.Connection.get_token()
    assert token.access_token != token2.access_token
  end

end
