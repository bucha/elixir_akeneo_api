defmodule AkeneoApiProductEndpointTest do
  use ExUnit.Case
  doctest AkeneoApi

  test "can update test product" do
    {:ok, product} = AkeneoApi.Endpoint.V1.Products.get_products "test-123"
    product = %{product | "values" => %{product["values"] | "name" => [%{"data" => "API Test 1", "locale" => "de_DE", "scope" => "ecommerce"}]}}
    assert {:ok, _res} = AkeneoApi.Endpoint.V1.Products.patch_products "test-123", body: product
  end

  test "can update test products in batch" do
    {:ok, product} = AkeneoApi.Endpoint.V1.Products.get_products "test-123"
    product = %{product | "values" => %{product["values"] | "name" => [%{"data" => "API Test 1", "locale" => "de_DE", "scope" => "ecommerce"}]}}

    payload = %{"items" => [product]}

    assert {:ok, _res} = AkeneoApi.Endpoint.V1.Products.patch_products body: payload
  end
end
