defmodule Mix.Tasks.GptFetch do
  @omit ~w(defs.json anchor.json dynamicRef.json id.json refRemote.json)

  alias Benchmark.GPT
  alias Benchmark.Schema

  def run([version]) do
    Application.ensure_all_started(:req)

    __DIR__
    |> Path.join("../../test/_draft2020-12")
    |> Path.expand()
    |> Schema.stream_from_directory(omit: @omit)
    |> Enum.each(&GPT.ensure_cached!(&1, version))
  end
end
