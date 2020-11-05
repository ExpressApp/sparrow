defmodule Sparrow.MixProject do
  use Mix.Project

  def project do
    [
      app: :sparrow,
      version: "1.1.1",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: description(),
      package: package(),
    ]
  end

  def application do
    [
      mod: {Sparrow.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

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
      links: %{"GitHub" => "https://github.com/ExpressApp/sparrow"}
    ]
  end
end
