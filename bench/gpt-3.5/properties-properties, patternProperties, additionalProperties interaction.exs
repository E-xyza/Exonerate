defmodule :"properties-properties, patternProperties, additionalProperties interaction-gpt-3.5" do
  def validate(json) when is_map(json) do
    case validate_object(json) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{}) do
    :ok
  end

  defp validate_object(_) do
    :error
  end

  defp validate_object(map) when is_map(map) and map["additionalProperties"] do
    add_props = map["additionalProperties"]

    case add_props["type"] do
      "integer" when Map.keys(map) -- ["additionalProperties"] == [] -> :ok
      _ -> :error
    end
  end

  defp validate_object(map) when is_map(map) and map["properties"] do
    props = map["properties"]

    {:ok, _} =
      Enum.reduce(Map.keys(props), {:ok, []}, fn key, {status, path} ->
        case validate_object(props[key]) do
          :ok -> {status, path}
          _ -> {:error, path ++ [key]}
        end
      end)
  end

  defp validate_object(map) when is_map(map) and map["patternProperties"] do
    pattern_props = map["patternProperties"]

    {:ok, _} =
      Enum.reduce(Map.keys(pattern_props), {:ok, []}, fn key, {status, path} ->
        match_key = String.replace(key, ".", "\\.")
        regexp = Regex.compile("^#{match_key}$")
        ids = Map.keys(map)
        matching_ids = Enum.filter(ids, fn id -> match?(regexp, id) end)

        case Enum.all?(matching_ids, fn matching_id -> validate_object(map[matching_id]) end) do
          true -> {status, path}
          _ -> {:error, path ++ [key]}
        end
      end)
  end

  defp validate_object(_) do
    :ok
  end
end
