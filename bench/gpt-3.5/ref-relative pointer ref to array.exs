defmodule :"relative pointer ref to array-gpt-3.5" do
  def validate(["prefixItems" | _] = schema) do
    validate_prefix_items(
      schema,
      []
    )
  end

  def validate(_) do
    :error
  end

  defp validate_prefix_items([], _) do
    :ok
  end

  defp validate_prefix_items([{"type", "integer"} | tail], acc) do
    validate_prefix_items(tail, [:integer | acc])
  end

  defp validate_prefix_items([{"$ref", "#/prefixItems/0"} | tail], acc) do
    validate_prefix_items(tail, [List.last(acc) | acc])
  end

  defp validate_prefix_items([_ | _], _) do
    :error
  end

  defp map_type("string") do
    :string
  end

  defp map_type("integer") do
    :integer
  end

  defp map_type("number") do
    :number
  end

  defp map_type("object") do
    :map
  end

  defp map_type("array") do
    :list
  end

  defp map_type(_) do
    :any
  end

  defp validate_type([], _) do
    :ok
  end

  defp validate_type([type | tail], value) when is_type(type, value) do
    validate_type(tail, value)
  end

  defp validate_type(_, _) do
    :error
  end

  defp is_type(:string, value) when is_binary(value) do
    true
  end

  defp is_type(:integer, value) when is_integer(value) do
    true
  end

  defp is_type(:number, value) when is_number(value) do
    true
  end

  defp is_type(:map, value) when is_map(value) do
    true
  end

  defp is_type(:list, value) when is_list(value) do
    true
  end

  defp is_type(:any, _) do
    true
  end

  defp is_type(_, _) do
    false
  end
end