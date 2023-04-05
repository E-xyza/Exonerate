defmodule :"patternProperties-multiple simultaneous patternProperties are validated" do
  def validate(object) when is_map(object) do
    valid_props = for {key, value} <- object, do: validate_prop(key, value)
    if length(valid_props) == length(object) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp validate_prop(key, value) do
    case validate_key(key, value) do
      :ok -> :ok
      :error -> validate_pattern_props(key, value)
    end
  end

  defp validate_key(key, _), do: if Regex.match?("^a*$", key) do :ok else :error end

  defp validate_pattern_props(key, value) do
    Enum.any?(patterns(), &validate_pattern_prop(&1, key, value))
  end

  defp validate_pattern_prop(pattern, key, value) do
    Regex.match?(pattern, key) && case pattern do
      "^a*$" -> is_integer(value)
      "^aaa*$" -> is_integer(value) && value <= 20
    end
  end

  defp patterns() do
    ["^a*$", "^aaa*$"]
  end
end
