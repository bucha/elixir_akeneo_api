defmodule AkeneoApiMediaEndpointTest do
  use ExUnit.Case
  doctest AkeneoApi

  test "can post a new image" do
    product = Jason.encode!(%{
      identifier: "test-123",
      attribute: "image",
      scope: nil,
      locale: nil
    })

    body = {:multipart, [
      {"product", product},
      {:file, "/home/bucha/Pictures/scoobydoo.jpeg"}
    ]}

    assert {:ok, _res} = AkeneoApi.Endpoint.V1.MediaFiles.post_media_files(body: body)
  end

end
