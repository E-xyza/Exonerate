defmodule :"regexes are not anchored by default and are case sensitive" do
  def validate(object) when is_map(object) do
    validate_pattern_properties(object, %{}, %{}, Map.keys(object))
  end

  def validate(_), do: :error

  defp validate_pattern_properties(_, _, _, []), do: :ok

  defp validate_pattern_properties(object, matched_patterns, errors, [key | tail]) do
    case validate_pattern_property(object, matched_patterns, errors, key) do
      {matched_patterns, errors} ->
        validate_pattern_properties(object, matched_patterns, errors, tail)
      :ok ->
        validate_pattern_properties(object, Map.put(matched_patterns, key, true), errors, tail)
    end
  end

  defp validate_pattern_property(object, matched_patterns, errors, key) do
    case Regex.run(~r/^X_/, key) do
      [_ | _] ->
        case Map.get(object, key) do
          value when is_binary(value) ->
            case Map.get(matched_patterns, key) do
              true ->
                {matched_patterns, errors}
              _ ->
                {Map.put(matched_patterns, key, true), errors}
            end
          _ ->
            {matched_patterns, [key | errors]}
        end
      nil ->
        case Regex.run(~r/^[0-9]{2,}/, key) do
          [_ | _] ->
            case Map.get(object, key) do
              value when is_boolean(value) ->
                case Map.get(matched_patterns, key) do
                  true ->
                    {matched_patterns, errors}
                  _ ->
                    {Map.put(matched_patterns, key, true), errors}
                end
              _ ->
                {matched_patterns, [key | errors]}
            end
          nil ->
            {matched_patterns, errors}
        end
    end
  end
end
