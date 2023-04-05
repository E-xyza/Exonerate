defmodule :"unevaluatedProperties with adjacent patternProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_properties(object, ^%{}, ^%{})
  end

  def validate(_) do
    :error
  end

  defp validate_properties(map, pattern_props, unmatched_props) do
    case Map.split(map, fn key, _value -> String.match?(~r/^foo$/, to_string(key)) end) do
      {matched_props, remaining_props} ->
        validated_props = Map.merge(unmatched_props, matched_props)
        validate_properties(remaining_props, pattern_props, validated_props)

      _, remaining_props when empty?(pattern_props) ->
        :ok

      _, _ ->
        :error
    end
  end
end