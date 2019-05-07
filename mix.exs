defmodule Sparrow.MixProject do
  use Mix.Project

  def project do
    [
      app: :sparrow,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
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

      {:mox, "~> 0.5", only: [:test]},
      {:plug, "~> 1.7", only: [:test]},
      {:plug_cowboy, "~> 2.0", only: [:test]},
    ]
  end
end
