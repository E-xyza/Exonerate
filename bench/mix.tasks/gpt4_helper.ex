defmodule Mix.Tasks.Gpt4Helper do
  @omit ~w(defs.json anchor.json dynamicRef.json id.json refRemote.json)

  alias Benchmark.GPT
  alias Benchmark.Schema

  def run(_) do
    directory =
      __DIR__
      |> Path.join("../../test/_draft2020-12")
      |> Path.expand()

    result =
      directory
      |> Schema.stream_from_directory(omit: @omit)
      |> Enum.each(fn schema ->
        schema.schema
        |> Jason.encode!()
        |> GPT.prompt(schema.description)
        |> IO.puts()

        IO.gets("enter to continue")
      end)
  end
end
