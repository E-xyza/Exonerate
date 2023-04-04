defmodule Benchmark.Library do
  @moduledoc false
  alias Benchmark.Schema

  @spec build_module(Schema.t()) :: Schema.t()

  def build_module(schema) do
    exonerate_compiled? = build_exonerate_module(schema)
    build_test_module(schema, exonerate_compiled?)
    schema
  end

  def build_exonerate_module(schema) do
    exonerate_module = exonerate_module(schema)
    schema_string = Jason.encode!(schema.schema)

    module_code =
      quote do
        defmodule unquote(exonerate_module) do
          require Exonerate

          Exonerate.function_from_string(:def, :validate, unquote(schema_string))
        end
      end

    try do
      Code.eval_quoted(module_code)
      true
    rescue
      _ -> false
    end
  end

  def build_test_module(schema, exonerate_compiled?) do
    module = test_module(schema)
    exonerate_module = if exonerate_compiled?, do: exonerate_module(schema)

    test_data =
      schema.tests
      |> Enum.map(& &1.data)
      |> Macro.escape()

    test_valids = Enum.map(schema.tests, & &1.valid)

    schema_ast = Macro.escape(schema.schema)

    quote do
      defmodule unquote(module) do
        require ExJsonSchema
        require JsonXema

        @schema unquote(schema_ast)
        @jsonxema JsonXema.new(@schema)

        @tests unquote(test_data)
               |> Enum.zip(unquote(test_valids))
               |> Map.new()

        unquote(ex_json_schema_function(schema))
        unquote(exonerate_function(schema, exonerate_compiled?))

        defp jsonxema(input) do
          JsonXema.validate(@jsonxema, input)
        end

        defp benchmark_map(input) do
          %{
            "Exonerate" => fn -> exonerate(input) end,
            "ExJsonSchema" => fn -> ex_json_schema(input) end,
            "JsonXema" => fn -> jsonxema(input) end
          }
        end

        defp benchmark_one({input, valid?}) do
          input
          |> benchmark_map()
          |> Benchmark.Library.validate(valid?)
          |> Benchee.run()
        end

        def benchmark do
          # run the benchmark once in ExJsonSchema and JsonXema and verify that they produce the
          # correct answer.
          @tests
          |> Enum.map(&benchmark_one/1)
          |> Benchmark.Library.save_results(unquote(schema.description))
        end
      end
    end
    |> Code.eval_quoted()
  end

  def validate(benchmark_map, valid?) do
    benchmark_map
    |> Enum.flat_map(fn pair = {name, benchmark} ->
      List.wrap(if verify(benchmark.(), valid?), do: pair)
    end)
    |> Map.new()
  end

  @spec verify(nil | :ok | {:error, term}, boolean()) :: boolean
  def verify(result, valid?) do
    # NB: result might be `nil` if we've marked that the function doesn't run at all.
    if result do
      result === :ok === valid?
    end
  end

  defp ex_json_schema_function(schema) do
    # ex_json_schema doesn't tolerate openapi schemas that are just boolean.  In this case,
    # just create a function that returns nil.
    if is_map(schema.schema) do
      quote do
        defp ex_json_schema(input) do
          ExJsonSchema.Validator.validate(@schema, input)
        end
      end
    else
      quote do
        defp ex_json_schema(_), do: nil
      end
    end
  end

  defp exonerate_function(schema, exonerate_compiled?) do
    # the exonerate module may not exist if the schema did not compile.
    # In this case, just create a function that returns nil.
    if exonerate_compiled? do
      quote do
        defp exonerate(input) do
          unquote(exonerate_module(schema)).validate(input)
        end
      end
    else
      quote do
        defp exonerate(_), do: nil
      end
    end
  end

  @results_file __DIR__
                |> Path.join("../results")
                |> Path.expand()

  def save_results(results, description) do
    file = Path.join(@results_file, "#{description}.bin")

    raise "not implemented"
  end

  defp test_module(schema), do: :"#{schema.description}"
  defp exonerate_module(schema), do: :"#{schema.description}-exonerate"
end
