defmodule :"uniqueItems=false with an array of items" do
  
defmodule Validator do
  def validate(decoded_json) do
    instructions = [
      %{"type" => "object"} => fn %{__struct__: _} -> :ok; _ -> :error end,
      %{"type" => "array", "items" => items} => fn [head | tail] ->
        Enum.reduce(tail, validate(head, items), fn item, :ok -> item_error(item); _, error -> error end)
      end,
      %{"type" => "integer"} => fn x when is_integer(x) -> :ok; _ -> :error end,
      %{"type" => "number"} => fn x when is_float(x) or is_integer(x) -> :ok; _ -> :error end,
      %{"type" => "string"} => fn x when is_binary(x) -> :ok; _ -> :error end,
      %{"type" => "boolean"} => fn true, true -> :ok; _, _ -> :error end,
      %{"enum" => enum_values} => fn x when Enum.member?(enum_values, x) -> :ok; _ -> :error end,
      %{"minItems" => min_items} => fn list when length(list) >= min_items -> :ok; _ -> :error end,
      %{"uniqueItems" => true} => fn list when length(list) == length(Enum.uniq(list)) -> :ok; _ -> :error end,
      %{"prefixItems" => prefix_items, "uniqueItems" => false} => fn list ->
        case List.split_at(list, length(prefix_items)) do
          {prefix_values, suffix_values} ->
            case Enum.all?(prefix_values, &validate(&1) == :ok) do
              true -> :ok
              false -> :error
            end
        end
      end,
      _ => fn _ -> :error end
    ]

    schema_to_instruction = fn schema -> elem(Enum.find_value(instructions, &match?(schema, &1)), 1) end
    validate = fn object, schema -> schema_to_instruction(schema).(object) end

    validate(decoded_json, %{"prefixItems" => [%{"type" => "boolean"}, %{"type" => "boolean"}], "uniqueItems" => false})
  end
end

end
