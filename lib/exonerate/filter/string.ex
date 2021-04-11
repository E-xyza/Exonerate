defmodule Exonerate.Filter.String do
  @moduledoc false
  # the filter for "string" parameters

  @behaviour Exonerate.Filter
  import Exonerate.Filter, only: [drop_type: 2]

  defguardp has_string_props(schema) when
    is_map_key(schema, "pattern") or
    is_map_key(schema, "minLength") or
    is_map_key(schema, "maxLength")

  @impl true
  def filter(schema, state = %{types: types}) when has_string_props(schema) and is_map_key(types, :string) do
    {[string_filter(schema, state.path)], drop_type(state, :string)}
  end
  def filter(_schema, state) do
    {[], state}
  end

  defp string_filter(schema, schema_path) do
    uses_length = if schema["minLength"] || schema["maxLength"] do
      quote do length = String.length(string) end
    end
    min_length = if min = schema["minLength"] do
      quote do
        (length < unquote(min)) && Exonerate.mismatch(string, path, schema_subpath: "minLength")
      end
    end
    max_length = if max = schema["maxLength"] do
      quote do
        (length > unquote(max)) && Exonerate.mismatch(string, path, schema_subpath: "maxLength")
      end
    end

    quote do
      defp unquote(schema_path)(string, path) when is_binary(string) do
        unquote(uses_length)
        unquote(min_length)
        unquote(max_length)
        unquote(pattern_call(schema["pattern"], schema_path))
      end
      unquote_splicing(pattern_helper(schema["pattern"], schema_path))
    end
  end

  defp pattern_call(nil, _), do: :ok
  defp pattern_call(_, schema_path) do
    pattern_helper = Exonerate.join(schema_path, "pattern")
    quote do
      unquote(pattern_helper)(string, path)
    end
  end

  defp pattern_helper(nil, _), do: []
  defp pattern_helper(pattern, schema_path) do
    pattern_helper = Exonerate.join(schema_path, "pattern")
    [quote do
      def unquote(pattern_helper)(string, path) do
        if string =~ sigil_r(<<unquote(pattern)>>, []) do
          :ok
        else
          Exonerate.mismatch(string, path)
        end
      end
    end]
  end
end
