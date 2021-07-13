defmodule ExonerateTest.AutomatedTests do
  @test_base_dir __DIR__
  |> Path.join("_draft2020-12")
  |> Path.expand()

  @omit ~w(defs.json anchor.json dynamicRef.json id.json infinite-loop-detection.json
    refRemote.json unevaluatedItems.json unevaluatedProperties.json)

  @test_omissions [
    # integer filters do not match float values:
    {"type.json", 0, 1},
    {"enum.json", 7, 2},
    {"enum.json", 8, 2}
  ]

  @describe_omissions [
    # integer filters do not match float values:
    {"multipleOf.json", 1},
    {"multipleOf.json", 2},
    {"multipleOf.json", 3},
    # no support for external uri's
    {"ref.json", 6},
    # no support for relative uri (for now)
    {"ref.json", 11},
    # currently no support for unevaluated
    {"ref.json", 13}
  ]

  def build_tests(directory \\ @test_base_dir) do
    directory
    |> File.ls!
    |> Enum.reject(&(&1 in @omit))
    |> Enum.flat_map(fn filename ->
      cond do
        Path.extname(filename) == ".json" ->
          [Path.join(directory, filename)]
        (_new_dir = directory |> Path.join(filename)) |> File.dir? ->
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
    Exonerate.Registry.sweep()

    module = Module.concat([ExonerateTest, String.capitalize(modulename), Test])
    describe_blocks = test_list
    |> Enum.with_index
    |> Enum.reject(fn {_, index} -> {path, index} in @describe_omissions end)
    |> Enum.map(&to_describe_block(&1, path))

    path_atom = path
    |> Path.basename
    |> String.to_atom

    quote do
      defmodule unquote(module) do
        use ExUnit.Case, async: true

        require Exonerate

        @moduletag :automated
        @moduletag unquote(path_atom)

        unquote(describe_blocks)
      end
    end
  end

  defp to_describe_block({%{"description" => description!, "schema" => schema!, "tests" => tests}, index}, path) do
    description! = "#{path}(#{index}) #{description!}"
    basename = Path.basename(path, ".json")
    schema_name = :"#{basename}_#{index}"
    schema! = Jason.encode!(schema!)
    test_blocks = tests
    |> Enum.with_index
    |> Enum.reject(fn {_test, inner_index} -> {path, index, inner_index} in @test_omissions end)
    |> Enum.map(&(elem(&1, 0)))
    |> Enum.map(&to_test_block(&1, schema_name))
    quote do
      describe unquote(description!) do
        Exonerate.function_from_string(:def, unquote(schema_name), unquote(schema!))
        unquote_splicing(test_blocks)
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
    |> Path.join("_draft2020-12/")
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
  require Exonerate

  @moduletag :isolate

  # uncomment the next line to test only one candidate.
  @tag :skip
  ExonerateTest.AutomatedTests.make("dependentSchemas.json", 0)
end
