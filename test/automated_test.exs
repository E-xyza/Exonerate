defmodule ExonerateTest.AutomatedTests do
  @test_base_dir __DIR__
  |> Path.join("draft2020-12")
  |> Path.expand()

  @omit ~w(defs.json anchor.json dynamicRef.json id.json infinite-loop-detection.json items.json ref.json
    refRemote.json unevaluatedItems.json unevaluatedProperties.json)

  @specific_omissions [
    {"type.json", 0},  # integer filters do not match exact integer floating point values.
  ]

  def build_tests(directory \\ @test_base_dir) do
    directory
    |> File.ls!
    |> Enum.reject(&(&1 in @omit))
    |> Enum.flat_map(fn filename ->
      cond do
        Path.extname(filename) == ".json" ->
          [Path.join(directory, filename)]
        (new_dir = directory |> Path.join(filename)) |> File.dir? ->
          # don't test optional stuff, for now.
          #build_tests(new_dir)
          []
        true -> []
      end
    end)
    |> Enum.each(fn path ->
      path
      |> File.read!
      |> Jason.decode!
      |> to_test_module(Path.basename(path, ".json"), Path.basename(path))
      |> Code.eval_quoted([], file: path)
    end)
  end

  defp to_test_module(test_list, modulename, path) do

    module = Module.concat([ExonerateTest, String.capitalize(modulename), Test])
    describe_blocks = test_list
    |> Enum.with_index
    |> Enum.reject(fn {_, index} -> {path, index} in @specific_omissions end)
    |> Enum.map(&to_describe_block(&1, path))

    quote do
      defmodule unquote(module) do
        use ExUnit.Case, async: true

        import Exonerate

        @moduletag :automated

        unquote(describe_blocks)
      end
    end
  end

  defp to_describe_block({%{"description" => description!, "schema" => schema!, "tests" => tests}, index}, path) do
    description! = "#{path}(#{index}) #{description!}"
    schema_name = :"test#{index}"
    schema! = Jason.encode!(schema!)
    test_blocks = Enum.map(tests, &to_test_block(&1, schema_name))
    quote do
      describe unquote(description!) do
        defschema([{unquote(schema_name), unquote(schema!)}])
        unquote(test_blocks)
      end
    end
  end

  defp to_test_block(%{"description" => description, "data" => data!, "valid" => true}, schema_name) do
    data! = Macro.escape(data!)
    quote do
      test unquote(description) do
        assert :ok = unquote(schema_name)(unquote(data!))
      end
    end
  end

  defp to_test_block(%{"description" => description, "data" => data!, "valid" => false}, schema_name) do
    data! = Macro.escape(data!)
    quote do
      test unquote(description) do
        assert {:error, _} = unquote(schema_name)(unquote(data!))
      end
    end
  end

  defmacro make(file, index) do
    path = __DIR__
    |> Path.join("draft2020-12/")
    |> Path.join(file)

    path
    |> File.read!
    |> Jason.decode!
    |> Enum.with_index
    |> Enum.at(index)
    |> to_describe_block(path)
  end
end

unless :isolate in ExUnit.configuration()[:include] do
  ExonerateTest.AutomatedTests.build_tests()
end

defmodule TestOneTest do
  use ExUnit.Case, async: true

  require ExonerateTest.AutomatedTests
  import Exonerate

  @moduletag :isolate

  ExonerateTest.AutomatedTests.make("exclusiveMaximum.json", 0)
end
