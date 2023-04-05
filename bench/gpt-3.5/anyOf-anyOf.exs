defmodule :"anyOf-gpt-3.5" do
  def validate(value) do
    if validate_anyof(value, [{"type", "integer"}, {"minimum", 2}]) do
      :ok
    else
      :error
    end
  end

  defp validate_anyof(value, subschemas) do
    Enum.any?(subschemas, &validate_schema(value, &1))
  end

  defp validate_schema(value, {"type", type}) do
    case type do
      "integer" -> is_integer(value)
      _ -> false
    end
  end

  defp validate_schema(value, {"minimum", min}) when is_integer(value) do
    value >= min
  end

  defp validate_schema(_, _) do
    false
  end
end