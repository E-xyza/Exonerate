defmodule ExonerateTest.Automate do
  def directory(directory, opts \\ []) do
    opts = Keyword.merge([omit_modules: [], omit_describes: [], omit_tests: [], prefix: X], opts)

    directory
    |> File.ls!()
    |> Enum.reject(&(&1 in opts[:omit_modules]))
    |> Enum.flat_map(fn filename ->
      cond do
        Path.extname(filename) == ".json" ->
          [Path.join(directory, filename)]

        (_new_dir = directory |> Path.join(filename)) |> File.dir?() ->
          # don't test optional stuff, for now.
          # build_tests(new_dir)
          []

        true ->
          []
      end
    end)
    |> Enum.each(fn path ->
      path
      |> File.read!()
      |> Jason.decode!()
      |> to_test_module(Path.basename(path, ".json"), Path.basename(path), opts)
      |> Code.eval_quoted([], file: path)
    end)
  end

  defp to_test_module(test_list, modulename, path, opts) do
    Exonerate.Registry.sweep()

    module = Module.concat([ExonerateTest, opts[:prefix], String.capitalize(modulename), Test])

    describe_blocks =
      test_list
      |> Enum.with_index()
      |> Enum.reject(fn {_, index} -> {path, index} in opts[:omit_describes] end)
      |> Enum.map(&to_describe_block(&1, path, opts))

    path_atom =
      path
      |> Path.basename()
      |> String.to_atom()

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

  defp to_describe_block(
         {%{"description" => description!, "schema" => schema!, "tests" => tests}, index},
         path,
         opts
       ) do
    description! = "#{path}(#{index}) #{description!}"
    basename = Path.basename(path, ".json")
    schema_name = :"#{basename}_#{index}"
    schema! = Jason.encode!(schema!)

    test_blocks =
      tests
      |> Enum.with_index()
      |> Enum.reject(fn {_test, inner_index} ->
        {path, index, inner_index} in opts[:omit_tests]
      end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(&to_test_block(&1, schema_name))

    quote do
      describe unquote(description!) do
        Exonerate.function_from_string(
          :def,
          unquote(schema_name),
          unquote(schema!),
          unquote(opts)
        )

        unquote_splicing(test_blocks)
      end
    end
  end

  defp to_test_block(
         %{"description" => description, "data" => data!, "valid" => true},
         schema_name
       ) do
    data! = Macro.escape(data!)

    quote do
      test unquote(description) do
        assert :ok = unquote(schema_name)(unquote(data!))
      end
    end
  end

  defp to_test_block(
         %{"description" => description, "data" => data!, "valid" => false},
         schema_name
       ) do
    data! = Macro.escape(data!)

    quote do
      test unquote(description) do
        assert {:error, _} = unquote(schema_name)(unquote(data!))
      end
    end
  end
end
