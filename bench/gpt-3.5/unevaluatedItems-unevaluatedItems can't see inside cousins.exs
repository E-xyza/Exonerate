defmodule :"unevaluatedItems can't see inside cousins-gpt-3.5" do
  def validate(json) do
    cond do
      is_valid(json, %{"allOf" => [%{"prefixItems" => [true]}, %{"unevaluatedItems" => false}]}) ->
        :ok

      true ->
        :error
    end
  end

  defp is_valid(json, schema) when is_map(schema) do
    cond do
      schema["type"] == "object" and is_map(json) ->
        true

      schema["type"] == "array" and is_list(json) ->
        true

      schema["type"] == "string" and is_binary(json) ->
        true

      schema["type"] == "number" and is_number(json) ->
        true

      schema["type"] == "integer" and is_integer(json) ->
        true

      schema["type"] == "boolean" and is_boolean(json) ->
        true

      schema["type"] == "null" and is_nil(json) ->
        true

      schema["allOf"] != nil and Enum.all?(schema["allOf"], &is_valid(json, &1)) ->
        true

      schema["anyOf"] != nil and Enum.any?(schema["anyOf"], &is_valid(json, &1)) ->
        true

      schema["oneOf"] != nil and Enum.count(schema["oneOf"], &is_valid(json, &1)) == 1 ->
        true

      schema["not"] != nil and not is_valid(json, schema["not"]) ->
        true

      is_map(json) and schema["additionalProperties"] == false and
          Map.keys(json) -- Map.keys(schema["properties"]) == [] ->
        true

      is_map(json) and schema["required"] != nil and
          Enum.all?(schema["required"], &Map.has_key?(json, &1)) ->
        true

      is_list(json) and is_integer(schema["minItems"]) and is_integer(schema["maxItems"]) and
        length(json) >= schema["minItems"] and length(json) <= schema["maxItems"] ->
        true

        is_list(json) and schema["items"] != nil and
          case schema["items"] do
            [] ->
              true

            [item_schema] ->
              Enum.all?(json, &is_valid(&1, item_schema))

            item_schemas ->
              length(item_schemas) == length(json) and
                Enum.all?(Enum.zip(json, item_schemas), fn {i, s} -> is_valid(i, s) end)
          end

      is_list(json) and schema["uniqueItems"] == true and Enum.uniq(json) == json ->
        true

      true ->
        false
    end
  end
end
