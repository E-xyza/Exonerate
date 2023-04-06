defmodule :"patternProperties-regexes are not anchored by default and are case sensitive-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Enum.all?(Map.keys(object), &is_valid_key/1) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp is_valid_key(key) do
    case String.match?(key, ~r/^X_|^[0-9]{2,}$/) do
      true -> is_valid_value(key, Map.get(key, object))
      false -> true
    end
  end

  defp is_valid_value(_, nil) do
    true
  end

  defp is_valid_value(_, value) when is_boolean(value) do
    true
  end

  defp is_valid_value(_, value) when is_binary(value) do
    true
  end

  defp is_valid_value(_, _) do
    false
  end
end