defmodule :"unevaluatedItems with anyOf-gpt-3.5" do
  def validate_array([], _, _) do
    :ok
  end

  def validate_array([head | tail], schema, position) do
    case validate_value(head, schema, position) do
      :ok -> validate_array(tail, schema, position + 1)
      error -> error
    end
  end

  def validate_value(value, schema, position) do
    case schema do
      %{"type" => "array"} when is_list(value) ->
        validate_array(value, schema, 0)

      %{"type" => "object"} when is_map(value) ->
        :ok

      %{"const" => const} when value == const ->
        :ok

      %{"prefixItems" => prefix_items, "anyOf" => any_of, "unevaluatedItems" => unevaluated_items}
      when is_list(value) ->
        case validate_array(prefix_items, schema, 0) do
          :ok ->
            Enum.any?(any_of, fn option ->
              validate_array(option["prefixItems"] ++ [value] ++ option["suffixItems"], schema, 0) ==
                :ok
            end)

          error ->
            error
        end

      error ->
        :error
    end
  end

  def validate(object) when is_list(object) do
    validate_array(object, schema, 0)
  end

  def validate(_) do
    :error
  end
end
