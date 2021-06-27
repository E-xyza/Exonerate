defmodule Exonerate.Filter.Number do
  @moduledoc false
  # the filter for "number" parameters

  alias Exonerate.Filter

  @behaviour Filter
  import Filter, only: [drop_type: 2]

  defguardp has_number_props(schema) when
    is_map_key(schema, "minimum") or
    is_map_key(schema, "maximum") or
    is_map_key(schema, "exclusiveMinimum") or
    is_map_key(schema, "exclusiveMaximum") or
    is_map_key(schema, "multipleOf")

  @impl true
  def filter(schema, state = %{types: types}) when has_number_props(schema) and is_map_key(types, :number) do
    {[number_filter(schema, state.path, state.extra_validations)], drop_type(state, :number)}
  end
  def filter(_schema, state) do
    {[], state}
  end

  defp number_filter(schema, schema_path, extra_validations) do
    guard_clauses =
      compare_guard(schema, "minimum", schema_path) ++
      compare_guard(schema, "maximum", schema_path) ++
      compare_guard(schema, "exclusiveMinimum", schema_path) ++
      compare_guard(schema, "exclusiveMaximum", schema_path) ++
      multiple_guard(schema, schema_path)

    quote do
      unquote_splicing(guard_clauses)
      defp unquote(schema_path)(value, path) when is_number(value) do
        require Exonerate.Filter
        Exonerate.Filter.apply_extra(unquote(extra_validations), value, path)
      end
    end
  end

  @operands %{
    "minimum" => :<,
    "maximum" => :>,
    "exclusiveMinimum" => :<=,
    "exclusiveMaximum" => :>=
  }

  defp compare_guard(schema, op, _) when not is_map_key(schema, op), do: []
  defp compare_guard(schema, op, schema_path) do
    compexpr = {@operands[op], [], [quote do number end, schema[op]]}
    [quote do
      defp unquote(schema_path)(number, path) when is_number(number) and unquote(compexpr) do
        Exonerate.mismatch(number, path, schema_subpath: unquote(op))
      end
    end]
  end

  defp multiple_guard(schema, _) when not is_map_key(schema, "multipleOf"), do: []
  defp multiple_guard(schema, schema_path) do
    factor = schema["multipleOf"]
    [quote do
      defp unquote(schema_path)(number, path) when is_integer(number) and rem(number, unquote(factor)) != 0 do
        Exonerate.mismatch(number, path, schema_subpath: "multipleOf")
      end
    end]
  end
end
