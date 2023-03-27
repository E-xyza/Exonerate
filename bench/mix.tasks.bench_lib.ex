defmodule Mix.Tasks.BenchLib do
  @shortdoc "benchmark against other libraries"
  use Mix.Task

  alias Benchmark.Complexity
  alias Benchmark.Test

  def run(_) do
    directory_draft7 =
      __DIR__
      |> Path.join("../test/_draft7")
      |> Path.expand()

    directory_draft7
    |> File.ls!()
    |> Enum.map(&Path.join(directory_draft7, &1))
    |> Enum.reject(&File.dir?/1)
    |> Enum.map(&File.read!/1)
    |> Enum.map(&Jason.decode!/1)
    |> Enum.flat_map(&unpack_tests/1)
    |> Enum.each(&run_module/1)
  end

  defp unpack_tests(file) do
    Enum.flat_map(file, fn test_set ->
      description = test_set["description"]
      schema = Jason.encode!(test_set["schema"])
      Enum.map(test_set["tests"], fn test ->
        %Test{
          module: :"#{description}: #{test["description"]}",
          schema: schema,
          value: Jason.encode!(test["data"]),
          valid: test["valid"]
        }
      end)
    end)
  end

  def run_module(test = %Test{}) do
    try do
      Benchmark.Library.build_module(test.module, test.schema, test.value, test.valid)
      |> Code.compile_quoted()
    rescue
      _ ->
        Benchmark.Library.build_module_no_exonerate(test.module, test.schema, test.value, test.valid)
        |> Code.compile_quoted()
    end

    IO.puts("Running #{test.module}")
    result = test.module.benchmark()

    encoded_result = result.scenarios
    |> Map.new(&extract_scenario_data(&1))
    |> Map.put_new("ExJsonSchema", nil)
    |> Map.put_new("Exonerate", nil)
    |> Map.put_new("JsonXema", nil)
    |> Map.put("complexity", Complexity.measure(Jason.decode!(test.schema)))  # TODO: measure complexity of uploaded modules?
    |> Map.put("valid_input", test.valid)
    |> IO.inspect

    bin = :erlang.term_to_binary(encoded_result)
    File.write!("bench/results/#{test.module}.bin", bin)
  end

  defp extract_scenario_data(scenario), do: {scenario.name, scenario.run_time_data.statistics.ips}
end
