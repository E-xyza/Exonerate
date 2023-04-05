defmodule :"format-validation of JSON pointers-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp validate_with_format(object, "json-pointer") do
    :ok
  end

  defp validate_with_format(_, _) do
    :error
  end

  defp validate_with_type(object, "object") do
    validate_map(object)
  end

  defp validate_with_type(object, "string") do
    validate_string(object)
  end

  defp validate_with_type(_, _) do
    :error
  end

  defp validate_map(object) when is_map(object) do
    :ok
  end

  defp validate_map(_) do
    :error
  end

  defp validate_string(object) when is_binary(object) do
    :ok
  end

  defp validate_string(_) do
    :error
  end
end
