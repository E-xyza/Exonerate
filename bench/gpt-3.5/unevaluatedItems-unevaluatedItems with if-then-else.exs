defmodule :"unevaluatedItems-unevaluatedItems with if-then-else" do

defmodule MySchema do
  def validate(schema) do
    case schema do
      %{"type" => "object"} -> validate_object()
      %{"type" => "array"} -> validate_array()
      _ -> :error
    end
  end

  defp validate_object(), do: fn object when is_map(object) -> :ok end
  defp validate_object(), do: fn _ -> :error end

  defp validate_array(), do: fn array when is_list(array) ->
    validate_array_items(array, [])
  end

  defp validate_array(), do: fn _ -> :error end

  defp validate_array_items([], []) -> :ok
  defp validate_array_items([], _) -> :error
  defp validate_array_items([item | rest], items) do
    case validate_array_item(item) do
      :ok -> validate_array_items(rest, [item | items])
      _ -> :error
    end
  end

  defp validate_array_item(value), do: validate(value)

  defp validate_array_item(%{ "const" => _ } = value) do
    fn array ->
      case array do
        [] -> :error
        [head | _] ->
          if head == value, do: :ok, else: :error
      end
    end
  end

  defp validate_array_item(%{ "type" => "array", "prefixItems" => prefix }) do
    if prefix == [], do: fn _ -> :ok end, else: build_array_validator(prefix)
  end

  defp validate_array_item(%{ "type" => "object", "prefixItems" => prefix }) do
    if prefix == [], do: fn _ -> :ok end, else: build_object_validator(prefix)
  end

  defp validate_array_item(_), do: fn _ -> :error end

  defp build_array_validator(prefix) do
    fn array ->
      case prefix do
        [item | rest] ->
          case validate_array_item(item).(array) do
            :ok -> build_array_validator(rest).(array)
            _ -> :error
          end
        [] -> validate_array_items(array, [])
      end
    end
  end

  defp build_object_validator(prefix) do
    fn object ->
      case prefix do
        [key | rest] ->
          case Map.get(object, key) do
            nil -> :error
            value ->
              case validate(value).(value) do
                :ok -> build_object_validator(rest).(object)
                _ -> :error
              end
          end
        [] -> validate_object().(object)
      end
    end
  end
end

end
