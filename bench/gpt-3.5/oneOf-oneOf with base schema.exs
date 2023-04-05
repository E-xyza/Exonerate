defmodule :"oneOf with base schema-gpt-3.5" do
  def validate(object) when is_map(object) and match_schema(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp match_schema(_object, []) do
    false
  end

  defp match_schema(object, [{"minLength", length} | tail]) when is_binary(object) do
    byte_size(object) >= length and match_schema(object, tail)
  end

  defp match_schema(object, [{"maxLength", length} | tail]) when is_binary(object) do
    byte_size(object) <= length and match_schema(object, tail)
  end

  defp match_schema(object, [{"type", "string"} | tail]) when is_binary(object) do
    match_schema(object, tail)
  end

  defp match_schema(_object, _head) do
    true
  end
end