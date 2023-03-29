defmodule :"patternProperties with boolean schemas-gpt-3.5" do
  def validate(%{} = object) do
    case validate_object_keys(object) and validate_pattern_properties(object) do
      true -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object_keys(object) do
    is_map(object)
  end

  defp validate_pattern_properties(object) do
    object
    |> Enum.reject(fn {key, _} -> match_regex?(key, ~r/b.*/) end)
    |> Enum.all?(fn {key, _} -> match_regex?(key, ~r/f.*/) end)
  end

  defp match_regex?(string, regex) do
    String.match?(string, regex)
  end
end
