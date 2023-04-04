defmodule Mix.Tasks.BenchLib do
  @shortdoc "benchmark against other libraries"
  use Mix.Task

  alias Benchmark.Complexity
  alias Benchmark.Library
  alias Benchmark.Schema
  alias Benchmark.Test

  @omit [
    "remote ref, containing refs itself",
    "by int",
    "with boolean schema false",
    "not with boolean schema false",
    "not with boolean schema true",
    "forbidden property",
    "not more complex schema",
    "not multiple types",
    "not",
    "items + contains",
    "contains keyword with boolean schema false",
    "contains keyword with boolean schema true",
    "contains keyword with const keyword",
    "contains keyword validation",
    "minItems validation",
    "nul characters in strings",
    "float and integers are equal up to 64-bit representation limits",
    "const with -2.0 matches integer and float types",
    "const with 1 does not match true",
    "const with 0 does not match other zero-like types",
    "const with {\"a\": true} does not match {\"a\": 1}",
    "const with {\"a\": false} does not match {\"a\": 0}",
    "const with [true] does not match [1]",
    "const with [false] does not match [0]",
    "const with true does not match 1",
    "const with false does not match 0",
    "const with null",
    "const with array",
    "const with object",
    "const validation",
    "boolean schema 'false'",
    "boolean schema 'true'",
    "maxProperties = 0 means the object is empty",
    "maxProperties validation",
    "minProperties validation",
    "minimum validation with signed integer",
    "minimum validation",
    "validation of URI templates",
    "validation of URI references",
    "validation of URIs",
    "validation of IRI references",
    "validation of IRIs",
    "validation of relative JSON pointers",
    "validation of JSON pointers",
    "validation of time strings",
    "validation of date-time strings",
    "validation of date strings",
    "validation of hostnames",
    "validation of IDN hostnames",
    "validation of IPv6 addresses",
    "validation of IP addresses",
    "validation of regexes",
    "validation of IDN e-mail addresses",
    "validation of e-mail addresses",
    "exclusiveMaximum validation"
  ]

  def run(_) do
    Application.put_env(
      :ex_json_schema,
      :remote_schema_resolver,
      {Benchmark.ExJsonSchemaResolver, :resolve}
    )

    Application.ensure_all_started(:bandit)

    Bandit.start_link(plug: Benchmark.FilePlug, scheme: :http, options: [port: 1234])

    directory_draft7 =
      __DIR__
      |> Path.join("../../test/_draft7")
      |> Path.expand()

    directory_draft7
    |> Schema.stream_from_directory(omit: @omit)
    |> Stream.map(&Library.build_module/1)
    |> Enum.take(1)
    |> Enum.each(&run_module/1)
  end

  defp run_module(schema) do
    IO.puts("Running #{schema.description}")

    :"#{schema.description}".benchmark()

    # move this to the Library module.
    # encoded_result = result.scenarios
    # |> Map.new(&extract_scenario_data(&1))
    # |> Map.put_new("ExJsonSchema", nil)
    # |> Map.put_new("Exonerate", nil)
    # |> Map.put_new("JsonXema", nil)
    # |> Map.put("complexity", Complexity.measure(schema))
    # |> Map.put("valid_input", test.valid)
    #
    # bin = :erlang.term_to_binary(encoded_result)
    # File.write!("bench/results/#{module}.bin", bin)
  end

  defp extract_scenario_data(scenario), do: {scenario.name, scenario.run_time_data.statistics.ips}
end
