defmodule :"non-ASCII pattern with additionalProperties-gpt-3.5" do
  def validate(%{} = object) do
    case Map.get(object, "additionalProperties") do
      false -> validate_pattern_properties(object)
      _ -> :ok
    end
  end

  def validate(_) do
    :error
  end

  defp validate_pattern_properties(object) do
    case Map.get(object, "patternProperties") do
      %{} = pattern_properties ->
        Enum.all?(pattern_properties, fn {pattern, _} ->
          Port.compile({:_, [], regex: [pattern], match: [:á]})
        end)

        :ok

      _ ->
        :error
    end
  end
end
