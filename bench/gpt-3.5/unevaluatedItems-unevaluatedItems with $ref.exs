defmodule :"unevaluatedItems-unevaluatedItems with $ref-gpt-3.5" do
  def validate(object) when is_list(object), do: validate_list(object)
  def validate(_), do: :error

  defp validate_list([], _), do: :ok
  defp validate_list([item | items], schema) do
    case validate_item(item, schema) do
      :ok -> validate_list(items, schema)
      _ -> :error
    end
  end

  defp validate_item(item, schema) when map_size(schema) == 1 and map.member?(schema, "type") do
    validate_type(item, schema.type)
  end
  defp validate_item(item, schema) when map_size(schema) == 1 and map.member?(schema, "$ref") do
    validate_ref(item, schema)
  end
  defp validate_item(item, schema) when map_size(schema) >= 1 and map.member?(schema, "prefixItems") do
    validate_prefix_items(item, schema)
  end

  defp validate_type(item, "array") when is_list(item), do: :ok
  defp validate_type(item, "object") when is_map(item), do: :ok
  defp validate_type(item, "string") when is_binary(item), do: :ok
  defp validate_type(item, _), do: :error

  defp validate_ref(item, schema) do
    ref_schema = regex_replace(schema.$ref, "#/", "")
                |> String.split(["/"])
                |> Enum.reduce(%{"$defs": schema.$defs}, fn key, acc -> acc[key] end)
    validate_item(item, ref_schema)
  end

  defp validate_prefix_items(items, schema) do
    case schema.prefixItems do
      [first | rest] ->
        case validate_item(first, %{"type": "array"}) do
          :ok ->
            case validate_list(rest, %{"type": "string"}) do
              :ok ->
                case validate_unevaluated_items(items, rest) do
                  :ok -> :ok
                  _ -> :error
                end
              _ -> :error
            end
          _ -> :error
        end
      _ -> :error
    end
  end

  defp validate_unevaluated_items([], _), do: :ok
  defp validate_unevaluated_items([item | items], schema) do
    case validate_item(item, schema) do
      :ok -> validate_unevaluated_items(items, schema)
      _ -> :error
    end
  end
end
