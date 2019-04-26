# Akeneo API client

This is an [Akeneo PIM] API client for Elixir. You'll need an API token which can be retrieved by following the [getting started guide].
In order to get an overview of the available endpoints, look up the [API reference].

[Akeneo PIM]: https://www.akeneo.com/
[getting started guide]: https://api.akeneo.com/getting-started-admin.html
[API reference]: https://api.akeneo.com/api-reference-index.html

## Installation

The package can be installed by adding `akeneo_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:akeneo_api, "~> 0.1.1"}
  ]
end
```

## Configuration

Start by adding the credentials and connection parameters for `akeneo_api` to your `config/config.exs`:

```elixir
config :akeneo_api,
    username: "USERNAME_HERE",
    password: "PASSWORD_HERE",
    client_id: "TOKEN_CLIENT_ID",
    secret: "TOKEN_SECRET",
    host: "https://AKENEO_INSTALLATION.tld",
    token_url: "https://AKENEO_INSTALLATION.tld/api/oauth/v1/token"
```

If you want to see what's going on behind the scenes, enable the `debug` mode of the `oauth2` module:

```elixir
config :oauth2, debug: true
```

## Usage

This module uses the Swagger JSON provided by Akeneo to build modules and functions on compile time.
Every endpoint lives under the namespace `AkeneoApi.Endpoint.V1` such as:
```
iex(1)> AkeneoApi.Endpoint.V1.
AssetCategories                AssetTags                      
Assets                         AssociationTypes               
AttributeGroups                Attributes                     
Categories                     Channels                       
Currencies                     Families                       
Locales                        MeasureFamilies                
MediaFiles                     ProductModels                  
Products                       PublishedProducts              
ReferenceEntities              ReferenceEntitiesMediaFiles
```

Within this code-generation, every `operationId` of the Swagger specification becomes its own function, while each parameter within the URL-path becomes a mandatory argument of this function.
The generated function's last parameter is an optional Keyword List, transporting `query:` and `body:` parameters.

### Simple example

Get a list of products:

```elixir
{:ok, product_list} = AkeneoApi.Endpoint.V1.Products.get_products
```

### Query example

Get a list of products filtered by name:

```elixir
filter = %{name: [%{operator: "CONTAINS", value: "test", locale: "de_DE", scope: "ecommerce"}]}
{:ok, product_list} = AkeneoApi.Endpoint.V1.Products.get_products(query: [limit: 100, page: 2, search: Jason.encode!(filter)])
```

Refer to the [API reference] as well as the [filter documentation] to further details.

[API reference]: https://api.akeneo.com/api-reference.html#get_products
[filter documentation]: https://api.akeneo.com/documentation/filter.html


### File example

```elixir
file = "/path/to/file

product = Jason.encode!(%{
  identifier: "product123",
  attribute: "image",
  scope: nil,
  locale: nil
})

body = {:multipart, [
  {"product", product},
  {:file, file}
]}

AkeneoApi.Endpoint.V1.MediaFiles.post_media_files(body: body)
```
