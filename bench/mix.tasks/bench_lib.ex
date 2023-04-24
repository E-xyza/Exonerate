defmodule Mix.Tasks.BenchLib do
  use Mix.Task

  @omit ~w(definitions.json)
  @omit_tests [
    {"ref", "remote ref, containing refs itself"},
    {"ref", "Location-independent identifier"},
    {"ref", "Location-independent identifier with absolute URI"},
    {"ref", "Location-independent identifier with base URI change in subschema"},
    {"refRemote", "base URI change - change folder"},
    {"refRemote", "base URI change - change folder in subschema"}
  ]

  alias Benchmark.Library
  alias Benchmark.Schema

  @remotes_dir Path.join(__DIR__, "../../test/_draft7/remotes")

  def run(_) do
    Application.ensure_all_started(:req)
    Application.ensure_all_started(:bandit)
    Application.put_env(:exonerate, :file_plug, @remotes_dir)

    Application.put_env(:ex_json_schema, :remote_schema_resolver, fn url ->
      Req.get!(url).body |> Jason.decode!()
    end)

    Application.put_env(:xema, :loader, JsonXema.Loader)

    Bandit.start_link(plug: ExonerateTest.FilePlug, scheme: :http, options: [port: 1234])

    __DIR__
    |> Path.join("../../test/_draft7")
    |> Path.expand()
    |> Schema.stream_from_directory(omit: @omit)
    |> Stream.flat_map(&Library.stream_schema(&1, omit: @omit_tests))
    |> Enum.each(fn {test_module, result} ->
      filepath = Path.join(__DIR__, "../results/#{test_module}.bin")
      binary = :erlang.term_to_binary(result)
      IO.puts("Writing to #{filepath}")
      File.write!(filepath, binary)
    end)
  end
end
