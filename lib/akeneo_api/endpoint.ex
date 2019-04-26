defmodule AkeneoApi.Endpoint do
  def get_documentation do
    File.read!("#{__DIR__}/akeneo_web_api.json")
    |> Jason.decode!
  end

  def get_url(pattern, arguments, query \\ []) do
    Enum.reduce(arguments, pattern, fn ({arg, val}, url) ->
      Regex.replace(~r/{#{to_string(arg)}}/, url, to_string(val), global: false)
    end) <> "?" <> :hackney_url.qs(query)
  end

  def get_documentation(%{} = spec) do
    spec["description"]
  end

end

endpoint_map = Enum.reduce(AkeneoApi.Endpoint.get_documentation["paths"], %{}, fn ({url, methods}, acc) ->
  matches = Regex.named_captures(~r/\/api\/rest\/(?<version>v1)\/(?<endpoint>.+?)(?:\/.*$|$)/, url)
  case matches do
    %{"endpoint" => endpoint, "version" => version} ->
      endpoint_spec = Enum.reduce(methods, %{}, fn ({method, definition}, methodAccumulator) ->
        AkeneoApi.Utils.Map.deep_merge(methodAccumulator, %{method => %{definition["operationId"] => Map.put(definition, "url", url)}})
      end)
      AkeneoApi.Utils.Map.deep_merge(acc, %{version => %{endpoint => endpoint_spec}})
    _ -> acc
  end
end)

Enum.each(endpoint_map, fn({version, endpoints}) ->
  #Regex.named_captures(~r/\/api\/rest\/(?<version>v1)\/(?<endpoint>.+?)(?:\/.*$|$)/, "/api/rest/v1/categories")
  Enum.each(endpoints, fn({endpoint, methods}) ->
    endpoint = Regex.replace(~r/-/, endpoint, "_")
    module = Module.concat([AkeneoApi.Endpoint, version |> Macro.camelize, endpoint |> Macro.camelize])

    defmodule module do
      Enum.each(methods, fn({http_method, calls}) ->
        Enum.each(calls, fn({operation_id, spec}) ->
          parameters                  = spec["parameters"] || %{}
          path_parameters             = parameters |> Enum.filter(&(&1["in"] == "path"))
          query_parameters            = parameters |> Enum.filter(&(&1["in"] == "query"))
          required_query_parameters   = query_parameters |> Enum.filter(&(&1["required"] == true))
          body_parameters             = parameters |> Enum.filter(&(&1["in"] == "body"))
          required_body_parameters    = body_parameters |> Enum.filter(&(&1["required"] == true))
          has_required_parameters     = !Enum.empty?(required_query_parameters) || !Enum.empty?(required_body_parameters)
          has_optional_parameters     = Enum.count(query_parameters) > Enum.count(required_query_parameters) || Enum.count(body_parameters) > Enum.count(required_body_parameters)

          content_type = if Enum.any?(body_parameters, fn param -> (param["x-form-data"] || false) == true end) do
            "multipart/form-data"
          else
            #"application/vnd.akeneo.collection+json"
            "application/json"
          end

          arguments = Enum.reduce(path_parameters, [], fn param, arg_acc ->
            arg_acc ++ [String.to_atom(param["name"])]
          end)

          function_arguments = arguments
          #|> Enum.map(fn name -> quote do <<unquote(Macro.var(name, nil))::unquote(Macro.var(:binary, Elixir))>> end end)
          #|> Enum.map(&(Macro.expand(&1, __MODULE__)))
          |> Enum.map(&(Macro.var(&1, nil)))

          function_name = Enum.reduce(path_parameters, operation_id,  fn param, function_name ->
            Regex.replace(~r/(__#{param["name"]}(?:__|_?$))/, function_name, "")
          end)
          |> String.to_atom

          internal_function_name = "internal_" <> (function_name |> Atom.to_string) |> String.to_atom


          documentation = AkeneoApi.Endpoint.get_documentation(spec)

          @url spec["url"]

          unless has_required_parameters && !has_optional_parameters do
            @doc """
            #{documentation}
            """
            def unquote(function_name)(unquote_splicing(function_arguments)) do
              unquote(internal_function_name)(unquote_splicing(function_arguments), [query: nil, body: nil])
            end
          end

          if has_required_parameters || has_optional_parameters do
            @doc """
            #{documentation}
            """
            def unquote(function_name)(unquote_splicing(function_arguments), opts = [_head | _tail]) do
              unquote(internal_function_name)(unquote_splicing(function_arguments), opts)
            end
          end

          defp unquote(internal_function_name)(unquote_splicing(function_arguments), opts = [_head | _tail]) do
            args = Enum.zip(unquote(arguments), [unquote_splicing(function_arguments)])
            url = AkeneoApi.Endpoint.get_url(@url, args, opts[:query] || [])
            body = opts[:body] || nil
            connection = opts[:connection] || AkeneoApi.Connection

            content_type = case body do
              %{"items" => _items} -> "application/vnd.akeneo.collection+json"
              _ -> unquote(content_type)
            end

            headers = List.keystore(opts[:headers] || [], "content-type", 0, {"content-type", content_type})

            case unquote(String.to_atom(http_method)) do
              :get -> AkeneoApi.Connection.get(url, connection)
              :post -> AkeneoApi.Connection.post(url, body, headers, connection)
              :patch -> AkeneoApi.Connection.patch(url, body, headers, connection)
              :put -> AkeneoApi.Connection.put(url, body, headers, connection)
              :delete -> AkeneoApi.Connection.delete(url)
            end
          end


        end)
      end)
    end

  end)
end)
