defmodule :"unevaluatedItems with $ref-gpt-3.5" do
  @jsonschema %{
    "$defs": %{bar: %{prefixItems: [true, %{type: "string"}]}},
    "$ref": "#/$defs/bar",
    prefixItems: [%{type: "string"}],
    type: "array",
    unevaluatedItems: false
  }
  def validate(object) when is_map(object) do
    case validate_object(@jsonschema, object) do
      [] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(schema, object) when is_map(schema) and is_map(object) do
    Enum.flat_map(schema, fn {key, value} ->
      case validate_property(key, value, object[key]) do
        [] -> []
        errors -> ["#{key}: #{inspect(errors)}"]
      end
    end)
  end

  defp validate_object(schema, object) when is_list(schema) and is_list(object) do
    if length(object) == length(schema) do
      Enum.flat_map(Enum.zip(schema, object), fn {item_schema, item} ->
        validate_object(item_schema, item)
      end)
    else
      ["array has wrong length"]
    end
  end

  defp validate_object(_schema, _object) do
    ["wrong type"]
  end

  defp validate_property("type", "object", object) do
    validate_object(object)
  end

  defp validate_property("type", "array", object) do
    validate_object(
      object,
      []
    )
  end

  defp validate_property("type", type, object) do
    if type == typeof(object) do
      []
    else
      ["expected type #{type}"]
    end
  end

  defp validate_property("items", schema, object) when is_list(object) do
    Enum.flat_map(object, fn item -> validate_object(schema, item) end)
  end

  defp validate_property("additionalItems", false, object) when is_list(object) do
    ["array has too many items"]
  end

  defp validate_property("properties", properties_schema, object)
       when is_map(properties_schema) and is_map(object) do
    properties_names = Map.keys(properties_schema)
    object_names = Map.keys(object)
    missing_names = properties_names -- object_names
    extra_names = object_names -- properties_names
    missing_errors = Enum.map(missing_names, &"missing property #{&1}")
    extra_errors = Enum.map(extra_names, &"unexpected property #{&1}")

    property_errors =
      for {name, schema} <- properties_schema do
        validate_object(schema, object[name])
      end

    missing_errors ++ extra_errors ++ Enum.flat_map(property_errors, & &1)
  end

  defp validate_property("required", required_names, object)
       when is_list(required_names) and is_map(object) do
    missing_names = required_names -- Map.keys(object)

    if missing_names == [] do
      []
    else
      ["missing required properties: #{inspect(missing_names)}"]
    end
  end

  defp validate_property("minLength", min_length, object) when is_binary(object) do
    if byte_size(object) >= min_length do
      []
    else
      ["string is too short"]
    end
  end

  defp validate_property("maxLength", max_length, object) when is_binary(object) do
    if byte_size(object) <= max_length do
      []
    else
      ["string is too long"]
    end
  end

  defp validate_property("enum", values, object) do
    if Enum.member?(values, object) do
      []
    else
      ["not in enum: #{inspect(values)}"]
    end
  end

  defp validate_property(_, _, _) do
    []
  end
end
