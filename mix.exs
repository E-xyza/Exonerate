defmodule Exonerate.MixProject do
  use Mix.Project

  def project do
    [
      app: :exonerate,
      version: "0.3.2",
      elixir: "~> 1.14.1",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: [
        description: "JSON Schema macro generator",
        licenses: ["MIT"],
        files: ~w(lib mix.exs README* LICENSE* VERSIONS*),
        links: %{"GitHub" => "https://github.com/E-xyza/exonerate"}
      ],
      source_url: "https://github.com/E-xyza/exonerate/",
      docs: [main: "Exonerate", source_ref: "master"],
      preferred_cli_env: [
        bench_lib: :bench,
        gpt4_helper: :bench,
        gpt_fetch: :bench,
        find_by_resource: :test
      ],
      test_coverage: [
        ignore_modules: [SchemaModule, ExonerateTest.Automate, Exonerate.Cache.Resource]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(:bench), do: ["lib", "bench", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:match_spec, "~> 0.3.1"},
      {:json_ptr, "~> 0.5"},
      {:jason, "~> 1.4.0"},
      # optional dependencies
      {:pegasus, "~> 0.2.2", optional: true},
      {:req, "~> 0.3", optional: true},
      {:finch, "~> 0.15", optional: true},
      {:yaml_elixir, "~> 2.7", optional: true},
      {:idna, "~> 6.1.1", optional: true},
      # dev tools
      {:ex_doc, "~> 0.29", only: :dev},
      {:dialyxir, "~> 1.2.0", only: :dev, runtime: false},
      # test
      {:bandit, "~> 0.7", only: [:test, :bench]},
      {:tzdata, "~> 1.1.1", only: :test},
      {:poison, "~> 5.0.0", only: :test},
      # benchmarking tools
      {:ex_json_schema, "~> 0.9.2", only: :bench},
      {:json_xema, "~> 0.3", only: :bench},
      {:benchee, "~> 1.1.0", only: :bench}
    ]
  end
end
