defmodule Exonerate.MixProject do
  use Mix.Project

  def project do
    [
      app: :exonerate,
      version: "0.2.2",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: [
        description: "JSON Schema macro generator",
        licenses: ["MIT"],
        files: ~w(lib mix.exs README* LICENSE* VERSIONS*),
        links: %{"GitHub" => "https://github.com/ityonemo/exonerate"}
      ],
      source_url: "https://github.com/ityonemo/exonerate/",
      docs: [main: "Exonerate"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.24", only: :dev},
      {:yaml_elixir, "~> 2.7", only: :test},
      {:jason, "~> 1.1"},
    ]
  end
end
