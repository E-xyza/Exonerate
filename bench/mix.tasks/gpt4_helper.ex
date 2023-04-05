defmodule Mix.Tasks.Gpt4Helper do
  @omit ~w(defs.json anchor.json dynamicRef.json id.json refRemote.json)

  @gpt4missing [
    {"type", "type: array, object or null"},
    {"ref", "remote ref, containing refs itself"},
    {"ref", "refs with quote"},
    {"unevaluatedProperties", "unevaluatedProperties with if-then-else"},
    {"allOf", "allOf"},
    {"dependentSchemas", "single dependency"},
    {"dependentSchemas", "dependencies with escaped characters"},
    {"enum", "nul characters in strings"},
    {"format", "validation of URIs"},
    {"const", "const with {\"a\": false} does not match {\"a\": 0}"},
    {"const", "const with {\"a\": true} does not match {\"a\": 1}"},
    {"const", "nul characters in strings"},
    {"unevaluatedItems", "unevaluatedItems false"},
    {"unevaluatedItems", "unevaluatedItems with if-then-else"},
    {"dependentRequired", "single dependency"},
    {"dependentRequired", "dependencies with escaped characters"},
    {"oneOf", "oneOf"}
  ]

  alias Benchmark.GPT
  alias Benchmark.Schema

  def run(_) do
    directory =
      __DIR__
      |> Path.join("../../test/_draft2020-12")
      |> Path.expand()

    result_dir = Path.join(__DIR__, "../gpt-4")

    result =
      directory
      |> Schema.stream_from_directory(omit: @omit)
      |> Stream.filter(&({&1.group, &1.description} in @gpt4missing))
      |> Enum.each(fn schema ->

        new_file = result_dir
        |> Path.join("#{schema.group}-#{schema.description}.exs")
        |> Path.expand()

        schema.schema
        |> Jason.encode!()
        |> GPT.prompt(schema.group, schema.description)
        |> IO.puts()

        File.touch(new_file)
        IO.puts(new_file)

        IO.gets("enter to continue")
        IO.puts("=====================================\n")
      end)
  end
end
