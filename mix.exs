defmodule Exonerate.MixProject do
  use Mix.Project

  def project do
    [
      app: :exonerate,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [exoneratebuildtests: :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 0.13", only: [:test]},
      {:jason, "~> 1.1"},
    ]
  end
end
