defmodule Sparrow.MixProject do
  use Mix.Project

  @source_url "https://github.com/ExpressApp/sparrow"
  @version "1.1.5"

  def project do
    [
      app: :sparrow,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      mod: {Sparrow.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:hackney, ">= 1.8.0"},
      {:jason, ">= 0.0.0", optional: true},
      {:mox, "~> 0.5", only: :test},
      {:plug, "~> 1.7", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Sentry client for Elixir based on the new Erlang's logger"
  end

  defp package do
    [
      name: :sparrow,
      maintainers: ["Yuri Artemev"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
