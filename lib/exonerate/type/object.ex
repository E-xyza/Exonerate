defmodule Exonerate.Type.Object do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Validator

  defstruct [:context, :fallback, needs_accumulator: false, filters: [], pipeline: [], arrows: [], pattern_pipeline: []]
  @type t :: %__MODULE__{}

  @validator_filters ~w(required maxProperties minProperties properties
    patternProperties additionalProperties dependentRequired dependentSchemas dependencies propertyNames)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  def parse(validator = %Validator{}, schema) do
    %__MODULE__{context: validator}
    |> Tools.collect(@validator_filters, fn
      artifact, filter when is_map_key(schema, filter) ->
        Filter.parse(artifact, @validator_modules[filter], schema)
      artifact, _ -> artifact
    end)
  end

  @spec compile(t) :: Macro.t
  def compile(artifact) do
    arrows = Enum.map(artifact.arrows, fn
      {key, target} ->
        Tools.arrow(
          [{key,
          Tools.variable(:value)}],
          call(target, key, Tools.variable(:value)))
    end)

    properties_fun = {:fn, [], arrows ++ [last_arrow(artifact)]}

    enum = if artifact.needs_accumulator do
      quote do Enum.each(object, unquote(properties_fun)) end
    else
      :ok
    end

    combining = Validator.combining(artifact.context, quote do object end, quote do path end)

    quote do
      defp unquote(Validator.to_fun(artifact.context))(object, path) when is_map(object) do
        Exonerate.pipeline(object, path, unquote(artifact.pipeline))
        unquote(enum)
        unquote_splicing(combining)
      end
    end
  end

  defp last_arrow(%__MODULE__{fallback: fallback, pattern_pipeline: []}) when not is_nil(fallback) do
    Tools.arrow(
      [{Tools.variable(:key),
      Tools.variable(:value)}],
      case fallback do
        {:name, fun} ->
          property_names(fun, Tools.variable(:key))
        false ->
          kv_mismatch(Tools.variable(:key), Tools.variable(:value))
        _ ->
          call(fallback, Tools.variable(:key), Tools.variable(:value))
      end)
  end
  defp last_arrow(%__MODULE__{fallback: fallback, pattern_pipeline: patterns = [_ | _]})do
    Tools.arrow(
      [{Tools.variable(:key),
      Tools.variable(:value)}],
      pattern_conditional(fallback, patterns, Tools.variable(:key), Tools.variable(:value))
    )
  end
  defp last_arrow(_) do
    Tools.arrow([{Tools.variable(:_), Tools.variable(:_)}], :ok)
  end

  defp property_names(fun, key_ast) do
    quote do
      unquote(fun)(unquote(key_ast), Path.join(path, unquote(key_ast)))
    end
  end

  defp call(fun, key_ast, value_ast) do
    quote do
      unquote(fun)(unquote(value_ast), Path.join(path, unquote(key_ast)))
    end
  end

  defp kv_mismatch(key, value) do
    quote do
      Exonerate.mismatch({unquote(key), unquote(value)}, path, guard: "additionalProperties")
    end
  end

  defp pattern_conditional(target, patterns, key_ast, val_ast) do
    final = case target do
      nil -> :ok
      false ->
        kv_mismatch(Tools.variable(:key), Tools.variable(:value))
      _ -> call(target, Tools.variable(:value), Tools.variable(:key))
    end

    quote do
      false
      |> Exonerate.pipeline({path, unquote(key_ast), unquote(val_ast)}, unquote(patterns))
      |> unless do
        unquote(final)
      end
    end
  end
end
