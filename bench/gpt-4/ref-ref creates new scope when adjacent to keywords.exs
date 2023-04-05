defmodule :"ref creates new scope when adjacent to keywords" do
  def validate(json) when is_map(json) do
    case Map.fetch(json, "prop1") do
      {:ok, prop1} when is_binary(prop1) ->
        validate_unevaluated_properties(json)

      _ ->
        {:error, "Invalid prop1"}
    end
  end

  def validate(_), do: {:error, "Invalid JSON value"}

  defp validate_unevaluated_properties(json) do
    known_properties = MapSet.new(["prop1"])
    json_properties = MapSet.new(Map.keys(json))

    case MapSet.difference(json_properties, known_properties) do
      difference when difference == MapSet.new() -> :ok
      _ -> {:error, "Invalid unevaluated properties"}
    end
  end
end
