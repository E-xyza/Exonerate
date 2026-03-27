defmodule Exonerate.Bowtie.Runner do
  @moduledoc """
  Handles dynamic schema compilation and validation for Bowtie test cases.
  """

  @doc """
  Run validation tests against a schema.

  Returns a list of result maps, one per test instance.
  """
  def run(schema, tests, registry, dialect) do
    # Generate a unique module name for this schema
    module_name = generate_module_name()

    # Build options based on dialect
    opts = build_opts(dialect, registry)

    try do
      # Compile the schema into a module
      compile_schema(module_name, schema, opts)

      # Run each test
      Enum.map(tests, fn test ->
        instance = test["instance"]
        run_single_test(module_name, instance)
      end)
    after
      # Clean up the compiled module
      :code.purge(module_name)
      :code.delete(module_name)
    end
  end

  defp generate_module_name do
    random = :crypto.strong_rand_bytes(8) |> Base.encode16()
    Module.concat([Exonerate.Bowtie.Dynamic, :"Schema_#{random}"])
  end

  defp build_opts(dialect, registry) do
    opts = []

    # Set draft based on dialect
    opts =
      case dialect do
        "https://json-schema.org/draft/2020-12/schema" ->
          Keyword.put(opts, :draft, "2020-12")

        "https://json-schema.org/draft/2019-09/schema" ->
          Keyword.put(opts, :draft, "2019-09")

        "http://json-schema.org/draft-07/schema#" ->
          Keyword.put(opts, :draft, "7")

        "http://json-schema.org/draft-06/schema#" ->
          Keyword.put(opts, :draft, "6")

        "http://json-schema.org/draft-04/schema#" ->
          Keyword.put(opts, :draft, "4")

        _ ->
          opts
      end

    # Add registry if present
    if map_size(registry) > 0 do
      Keyword.put(opts, :registry, registry)
    else
      opts
    end
  end

  defp compile_schema(module_name, schema, opts) do
    schema_json = Jason.encode!(schema)

    # Build the module AST
    module_ast =
      quote do
        defmodule unquote(module_name) do
          require Exonerate

          Exonerate.function_from_string(:def, :validate, unquote(schema_json), unquote(opts))
        end
      end

    # Compile the module
    [{^module_name, _binary}] = Code.compile_quoted(module_ast)
    :ok
  end

  defp run_single_test(module_name, instance) do
    case apply(module_name, :validate, [instance]) do
      :ok ->
        %{valid: true}

      {:ok} ->
        %{valid: true}

      {:error, _errors} ->
        %{valid: false}

      other ->
        # Unexpected return value
        %{
          errored: true,
          context: %{
            message: "Unexpected validation result: #{inspect(other)}"
          }
        }
    end
  end
end
