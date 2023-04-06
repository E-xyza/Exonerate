defmodule :"patternProperties-multiple simultaneous patternProperties are validated-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object) do
      [] ->
        :ok

      keys ->
        key_errors =
          Enum.reduce(keys, [], fn key, acc ->
            pattern_matcher = key_pattern_matcher(key)

            case Enum.find(pattern_properties(), pattern_matcher, nil) do
              nil ->
                acc ++ ["#{key} was not matched by patternProperties"]

              property_schema ->
                case validate_property(key, Map.get(object, key), property_schema) do
                  :ok -> acc
                  error -> acc ++ [error]
                end
            end
          end)

        case key_errors do
          [] -> :ok
          _ -> {:error, key_errors}
        end
    end
  end

  def validate(_) do
    :error
  end

  defp pattern_properties do
    [
      &(%{type: "integer"} =
          Map.get(
            &1,
            "a*"
          )),
      &(%{maximum: 20} =
          Map.get(
            &1,
            "aaa*"
          ))
    ]
  end

  defp key_pattern_matcher(key) do
    case Regex.run(~r/a+/, key) do
      [match] -> match
      _ -> nil
    end
  end

  defp validate_property(key, value, schema) do
    case schema do
      %{type: "integer"} ->
        case Integer.parse(value) do
          {num, _} when is_integer(num) -> :ok
          _ -> "#{key} value must be an integer"
        end

      %{maximum: max} ->
        case Integer.parse(value) do
          {num, _} when num <= max -> :ok
          _ -> "#{key} value must be less than or equal to #{max}"
        end

      _ ->
        "#{key} has an invalid schema"
    end
  end
end