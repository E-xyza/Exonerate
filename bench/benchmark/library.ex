defmodule Benchmark.Library do
  defstruct [:group, :description, :test, :exonerate, :ex_json_schema, :json_xema]

  def stream_schema(schema, opts \\ []) do
    schema.tests
    |> Stream.reject(&file_exists?(schema, &1))
    |> Stream.reject(&omitted_test?(schema, &1, opts))
    |> Stream.map(&run_one_test(schema, &1))
  end

  defp file_exists?(schema, test) do
    normalized = String.replace(test.description, "/", "-")

    filename =
      Path.join(__DIR__, "../results/#{schema.group}-#{schema.description}-#{normalized}.bin")

    File.exists?(filename)
  end

  defp omitted_test?(schema, test, opts) do
    case Keyword.get(opts, :omit) do
      nil ->
        false

      omit ->
        {schema.group, schema.description} in omit or
          {schema.group, schema.description, test.description} in omit
    end
  end

  defp run_one_test(schema, test) do
    # try to compile the exonerate module.
    IO.puts("compiling #{schema.group}-#{schema.description}-#{test.description}")

    try do
      {{_, module, _, _}, _} =
        schema
        |> attempt_compilation(test, true)
        |> Code.eval_quoted()

      module.run()
    rescue
      err ->
        IO.inspect(err)
        IO.inspect(__STACKTRACE__)
        IO.puts("=======================")
        []
    end
  end

  defp normalize(string), do: String.replace(string, "/", "-")

  defp attempt_compilation(schema, test, with_exonerate) do
    module_name = :"#{schema.group}-#{schema.description}-#{normalize(test.description)}"

    schema_str = Jason.encode!(schema.schema)

    exonerate_code =
      if with_exonerate do
        quote do
          require Exonerate

          Exonerate.function_from_string(:defp, :validate, unquote(schema_str),
            force_remote: true,
            cache: false
          )

          defp exonerate, do: validate(@test_data)

          defp maybe_add_exonerate(map), do: Map.put(map, :exonerate, &exonerate/0)
        end
      else
        quote do
          defp maybe_add_exonerate(map), do: map
        end
      end

    schema_ast = Macro.escape(schema.schema)

    quote do
      defmodule unquote(module_name) do
        @test_data unquote(Macro.escape(test.data))

        unquote(exonerate_code)

        @ex_json_schema_resolved (try do
                                    ExJsonSchema.Schema.resolve(unquote(schema_ast))
                                  rescue
                                    _ -> nil
                                  end)

        defp maybe_add_ex_json_schema(map) do
          if @ex_json_schema_resolved do
            try do
              ex_json_schema()
              Map.put(map, :ex_json_schema, &ex_json_schema/0)
            rescue
              _ -> map
            end
          else
            map
          end
        end

        defp ex_json_schema do
          ExJsonSchema.Validator.valid?(@ex_json_schema_resolved, @test_data)
        end

        @json_xema_preparsed (try do
                                JsonXema.new(unquote(schema_ast))
                              rescue
                                _ -> nil
                              end)

        defp maybe_add_json_xema(map) do
          if @json_xema_preparsed do
            try do
              json_xema()
              Map.put(map, :json_xema, &json_xema/0)
            rescue
              _ -> map
            end
          else
            map
          end
        end

        defp json_xema do
          JsonXema.validate(@json_xema_preparsed, @test_data)
        end

        def run do
          benchee =
            %{}
            |> maybe_add_ex_json_schema()
            |> maybe_add_json_xema()
            |> maybe_add_exonerate()
            |> Benchee.run()

          {unquote(module_name), benchee}
        end
      end
    end
  end
end
