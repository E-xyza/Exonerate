defmodule Exonerate.MixProject do
  use Mix.Project

  def project do
    [
      app: :exonerate,
      version: "1.2.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      package: [
        description: "JSON Schema macro generator",
        licenses: ["MIT"],
        files: ~w(lib mix.exs README* LICENSE* VERSIONS*),
        links: %{"GitHub" => "https://github.com/E-xyza/exonerate"}
      ],
      source_url: "https://github.com/E-xyza/exonerate/",
      docs: [
        main: "Exonerate",
        source_ref: "master",
        extras: ["guides/formatting.md"],
        groups_for_extras: [Guides: ~r/guides\/.*/]
      ],
      preferred_cli_env: [
        bench_lib: :bench,
        gpt4_helper: :bench,
        gpt_fetch: :bench,
        find_by_resource: :test,
        "bowtie.harness": :test
      ],
      test_coverage: [
        ignore_modules: [SchemaModule, ExonerateTest.Automate, Exonerate.Cache.Resource]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(:bench), do: ["lib", "bench", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:match_spec, "~> 1.0"},
      {:json_ptr, "~> 1.0"},
      {:jason, "~> 1.4", optional: true},
      # optional dependencies
      {:pegasus, "~> 1.0", optional: true},
      {:req, "~> 0.5", optional: true},
      {:finch, "~> 0.19", optional: true},
      {:yamerl, "~> 0.10", optional: true},
      {:decimal, "~> 2.0", optional: true},
      # dev tools
      {:ex_doc, "~> 0.35", only: :dev},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # test
      {:bandit, "~> 1.6", only: [:test, :bench]},
      {:tzdata, "~> 1.1", only: :test},
      {:poison, "~> 6.0", only: :test},
      # benchmarking tools
      {:ex_json_schema, "~> 0.10", only: :bench},
      {:json_xema, "~> 0.6", only: :bench},
      {:benchee, "~> 1.3", only: :bench}
    ]
  end
end
