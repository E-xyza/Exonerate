defmodule :"unevaluatedProperties-unevaluatedProperties with not-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_properties(object) and validate_required(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(object) do
    case Map.has_key?(object, "foo") do
      true -> validate_type(object["foo"], "string")
      false -> true
    end
  end

  defp validate_properties(_) do
    true
  end

  defp validate_required(object) do
    case Map.has_key?(object, "bar") do
      true -> validate_const(object["bar"], "bar")
      false -> true
    end
  end

  defp validate_required(_) do
    true
  end

  defp validate_type(object, "string") do
    is_binary(object) || is_string(object)
  end

  defp validate_type(object, "object") do
    is_map(object)
  end

  defp validate_type(_, _) do
    false
  end

  defp validate_const(object, "bar") do
    object == "bar"
  end

  defp validate_const(_, _) do
    false
  end
end
