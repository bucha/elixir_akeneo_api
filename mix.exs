defmodule AkeneoApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :akeneo_api,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Akeneo API client",
      source_url: "https://github.com/bucha/elixir_akeneo_api"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AkeneoApi, []}
    ]
  end

  defp deps do
    [
      {:oauth2, "~> 1.0"},
      {:jason, "~> 1.1"}
    ]
  end

  defp description() do
    "An Akeneo PIM API client for Elixir"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bucha/elixir_akeneo_api"}
    ]
  end
end
