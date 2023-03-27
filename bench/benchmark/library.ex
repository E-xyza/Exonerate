defmodule Benchmark.Library do
  @moduledoc false

  def verify({_, result}, valid) do
    case result.() do
      :ok when valid -> true
      :ok -> false
      {:error, _} when valid -> false
      {:error, _} -> true
    end
  end

  def build_module(module, schema_json, test_json, should_pass) do
    quote do
      defmodule unquote(module) do
        require Exonerate
        Exonerate.function_from_string(:defp, :exonerate, unquote(schema_json))

        @schema Jason.decode!(unquote(schema_json))
        @test_json Jason.decode!(unquote(test_json))

        def benchmark do
          # run the benchmark once in ExJsonSchema and JsonXema and verify that they produce the
          # correct answer.

          %{
            "Exonerate" => fn -> exonerate(@test_json) end,
            "ExJsonSchema" => fn -> ExJsonSchema.Validator.validate(@schema, @test_json) end,
            "JsonXema" => fn -> JsonXema.validate(JsonXema.new(@schema), @test_json) end
          }
          |> Enum.filter(&Benchmark.Library.verify(&1, unquote(should_pass)))
          |> Map.new()
          |> Benchee.run(print: [benchmarking: false, configuration: false, fast_warning: false])
        end
      end
    end
  end

  def build_module_no_exonerate(module, schema_json, test_json, should_pass) do
    quote do
      defmodule unquote(module) do
        require ExJsonSchema
        require JsonXema

        @schema Jason.decode!(unquote(schema_json))
        @test_json Jason.decode!(unquote(test_json))

        def benchmark do
          # run the benchmark once in ExJsonSchema and JsonXema and verify that they produce the
          # correct answer.

          %{
            "ExJsonSchema" => fn -> ExJsonSchema.Validator.validate(@schema, @test_json) end,
            "JsonXema" => fn -> JsonXema.validate(JsonXema.new(@schema), @test_json) end
          }
          |> Enum.filter(&Benchmark.Library.verify(&1, unquote(should_pass)))
          |> Map.new()
          |> Benchee.run(
            print: [benchmarking: false, configuration: false, fast_warning: false],
            console: [comparison: false]
          )
        end
      end
    end
  end
end
