defmodule Exonerate.Type.Object do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Validator

  defstruct [:context, :additional_properties, filters: [], pipeline: [], arrows: [], patterns: []]
  @type t :: %__MODULE__{}

  @validator_filters ~w(required maxProperties minProperties properties patternProperties additionalProperties)
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
          call(target, Tools.variable(:value), key))
    end)

    properties_fun = {:fn, [], arrows ++ [last_arrow(artifact)]}

    quote do
      defp unquote(Validator.to_fun(artifact.context))(object, path) when is_map(object) do
        Exonerate.pipeline(object, path, unquote(artifact.pipeline))
        Enum.each(object, unquote(properties_fun))
      end
    end
  end

  defp last_arrow(%{additional_properties: target, patterns: []}) when not is_nil(target) do
    Tools.arrow(
      [{Tools.variable(:key),
      Tools.variable(:value)}],
      if target do
        call(target, Tools.variable(:value), Tools.variable(:key))
      else # it could be false.
        kv_mismatch(Tools.variable(:key), Tools.variable(:value))
      end)
  end
  defp last_arrow(%{additional_properties: target, patterns: patterns = [_ | _]})do
    Tools.arrow(
      [{Tools.variable(:key),
      Tools.variable(:value)}],
      pattern_conditional(target, patterns, Tools.variable(:key), Tools.variable(:value))
    )
  end
  defp last_arrow(_) do
    Tools.arrow([{Tools.variable(:_), Tools.variable(:_)}], :ok)
  end

  defp call(fun, value_ast, nexthop) do
    quote do
      unquote(fun)(unquote(value_ast), Path.join(path, unquote(nexthop)))
    end
  end

  defp kv_mismatch(key, value) do
    quote do
      Exonerate.mismatch({unquote(key), unquote(value)}, path, guard: "additionalProperties")
    end
  end

  defp pattern_conditional(_target, patterns, key_ast, val_ast) do
    arrows = Enum.flat_map(patterns, fn {path, pattern} ->
      quote do
        Regex.match?(sigil_r(<<unquote(pattern)>>, []), unquote(key_ast)) ->
          unquote(path)(unquote(key_ast), unquote(val_ast))
      end
    end)

    {:cond, [], [[do: arrows]]}
  end
end
