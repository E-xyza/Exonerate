defmodule Mix.Tasks.BenchGpt do
  @shortdoc "benchmark against GPT variants"
  use Mix.Task

  alias Benchmark.GPT
  alias Benchmark.Schema

  @models ~w(3.5 4)

  @omit ~w(defs.json anchor.json dynamicRef.json id.json refRemote.json)

  def run([model]) when model in @models do
    Application.ensure_all_started(:req)

    directory =
      __DIR__
      |> Path.join("../../test/_draft2020-12")
      |> Path.expand()

    result =
      directory
      |> Schema.stream_from_directory(omit: @omit)
      |> Stream.map(&GPT.ensure_cached!(&1, model))
      |> Enum.map(&run_tests(&1, model))
      |> Map.new()

    File.write!("gpt-#{model}.bin", :erlang.term_to_binary(result))
  end

  defp run_tests(schema, model) do
    module = GPT.module_name(schema.description, model)
    {schema.description, gpt_valid?(schema, module, model)}
  end

  defp gpt_valid?(schema, module, model) do
    try do
      __DIR__
      |> Path.join("../gpt-#{model}/#{schema.description}.exs")
      |> Code.eval_file()

      Enum.all?(
        for test <- schema.tests do
          run_validation(test, module)
        end
      )
    rescue
      _ -> false
    end
  end

  defp run_validation(test, module) do
    case test do
      %{valid: true} -> module.validate(test.data) === :ok
      %{valid: false} -> module.validate(test.data) === :error
    end
  rescue
    _ -> false
  end
end
