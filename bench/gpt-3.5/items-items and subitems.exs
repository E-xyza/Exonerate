defmodule :"items-items and subitems-gpt-3.5" do
  def validate(object) when is_list(object) do
    if validate_items(object) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp validate_items(items) when is_list(items) do
    items
    |> Enum.all?(&validate_item/1)
  end

  defp validate_items(_), do: false

  defp validate_item(item) when is_map(item) do
    validation_result = for prefix_item <- schema[:prefixItems] do
      case prefix_item do
        %{"$ref" => ref} ->
          item
          |> Map.get(ref |> String.split("/") |> Enum.reject(&(&1 == "")))
          |> validate_subitem()
        subitem_schema ->
          validate_schema(subitem_schema, item)
      end
    end

    if validation_result == [:ok | _] do
      true
    else
      false
    end
  end

  defp validate_item(_), do: false

  defp validate_subitem(subitem) when is_map(subitem) do
    if validate_schema(schema[:$defs][:sub-item], subitem) do
      :ok
    else
      :error
    end
  end

  defp validate_subitem(_), do: :error

  defp validate_schema(schema, value) do
    case schema[:type] do
      "array" ->
        case schema[:items] do
          false ->
            true
          items_schema ->
            value
            |> validate_items()
        end
      "object" ->
        case schema[:required] do
          nil ->
            true
          required_fields ->
            required_fields
            |> Enum.all?(&Map.has_key?(value, &1))
        end
    end
  end
end
