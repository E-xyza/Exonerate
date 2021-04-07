defmodule ExonerateTest.AutomatedTests do

  @test_base_dir __DIR__
  |> Path.join("draft2020-12")
  |> Path.expand()

  @omit ~w(defs.json anchor.json dynamicRef.json id.json infinite-loop-detection.json items.json ref.json
    refRemote.json unevaluatedItems.json unevaluatedProperties.json)

  def build_tests(directory \\ @test_base_dir) do
    directory
    |> File.ls!
    |> Enum.reject(&(&1 in @omit))
    |> Enum.flat_map(fn filename ->
      cond do
        Path.extname(filename) == ".json" ->
          [Path.join(directory, filename)]
        (new_dir = directory |> Path.join(filename)) |> File.dir? ->
          build_tests(new_dir)
          []
        true -> []
      end
    end)
    |> Enum.map(fn path ->
      path
      |> File.read!
      |> Jason.decode!
      |> to_test_module(Path.basename(path, ".json"))
    end)
    |> Code.eval_quoted
  end

  defp to_test_module(test_list, modulename) do

    module = Module.concat([ExonerateTest, modulename, Test])
    describe_blocks = test_list
    |> Enum.with_index
    |> Enum.map(&to_describe_block/1)

    quote do
      defmodule unquote(module) do
        use ExUnit.Case, async: true

        import Exonerate

        unquote(describe_blocks)
      end
    end
  end

  defp to_describe_block({%{"description" => description!, "schema" => schema!, "tests" => tests}, index}) do
    description! = "(#{index})#{description!}"
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
        assert {:mismatch, _} = unquote(schema_name)(unquote(data!))
      end
    end
  end
end

ExonerateTest.AutomatedTests.build_tests()
