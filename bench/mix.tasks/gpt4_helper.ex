defmodule Mix.Tasks.Gpt4Helper do
  @omit ~w(defs.json anchor.json dynamicRef.json id.json refRemote.json)

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
      |> Enum.each(fn schema ->
        new_file =
          result_dir
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
