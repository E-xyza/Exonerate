defmodule :"items-items and subitems" do
  
defmodule Validator do

  def validate(object) when is_list(object) do
    items_valid = Enum.all?(object, fn item -> validate_item(item) == :ok end)
    if items_valid do
      :ok
    else
      :error
    end
  end

  def validate(object) when is_map(object) do
    schema = %{
      "$defs": %{
        "item": %{
          "items": false,
          "prefixItems": [{"$ref": "#/$defs/sub-item"}, {"$ref": "#/$defs/sub-item"}],
          "type": "array"
        },
        "sub-item": %{
          "required": ["foo"],
          "type": "object"
        }
      },
      "items": false,
      "prefixItems": [{"$ref": "#/$defs/item"}, {"$ref": "#/$defs/item"}, {"$ref": "#/$defs/item"}],
      "type": "array"
    }

    validate_map(object, schema)
  end

  def validate(_), do: :error

  defp validate_map(object, schema) do
    case schema do
      %{"required" => required_fields} ->
        if Enum.all?(required_fields, &Map.has_key?(object, &1)) do
          :ok
        else
          :error
        end

      %{"type" => "object", "properties" => properties_schema} ->
        case properties_schema do
          %{} ->
            # Empty schema means any object is valid
            :ok

          _ ->
            # Validate that all properties are present and valid
            property_names = Map.keys(properties_schema)
            if Enum.all?(property_names, fn name ->
              Map.has_key?(object, name) && validate(Map.get(object, name), Map.get(properties_schema, name)) == :ok
            end) do
              :ok
            else
              :error
            end
        end

      %{"type" => "array", "items" => item_schema} ->
        case item_schema do
          %{} ->
            # Empty schema means any array is valid
            :ok

          _ ->
            # Validate that all items are present and valid
            if Enum.all?(object, fn item -> validate(item, item_schema) == :ok end) do
              :ok
            else
              :error
            end
        end

      %{"type" => "array", "prefixItems" => prefix_items_schema} ->
        # Validate that prefix items are present and valid
        if Enum.all?(prefix_items_schema, fn item_schema -> validate_item(item_schema) == :ok end) do
          # Validate that remaining items are present and valid
          if Enum.with_index(object) |> Enum.drop(Enum.count(prefix_items_schema)) |> Enum.all?(fn {item, index} ->
            validate_item(item, Enum.at(prefix_items_schema, index)) == :ok
          end) do
            :ok
          else
            :error
          end
        else
          :error
        end

      %{"anyOf" => schemas} ->
        # Validate that object matches at least one of the schemas
        if Enum.any?(schemas, fn schema -> validate_map(object, schema) == :ok end) do
          :ok
        else
          :error
        end

      {"$ref" => ref_path} ->
        # Resolve reference and validate with referenced schema
        ref_schema = resolve_ref(ref_path)
        validate_map(object, ref_schema)

      _ ->
        # Invalid schema
        :error
    end
  end

  defp validate_item(item, schema \\ %{}) do
    validate(item, schema)
  end

  defp resolve_ref(ref_path) do
    # Naive implementation to resolve $refs from the same schema
    # Assumes that $refs are always in the form "#/$path/to/definition"
    definition_path = ref_path |> String.slice(2, String.length(ref_path) - 1)
    definition_path |> String.split("/") |> Enum.reduce(@schema, fn key, acc -> Map.get(acc, key) end)
  end

end

end
