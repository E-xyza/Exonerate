defmodule :"unevaluatedProperties with if/then/else" do
   elixir
defmodule :"unevaluatedProperties-unevaluatedProperties with if/then/else" do
  def validate(%{type: "object"} = object) do
    if Map.is_map(object) do
      :ok
    else
      :error
    end
  end

  def validate(object) do
    :error
  end

  def validate(%{type: "object", properties: properties} = object) do
    if Map.is_map(object) do
      case validate_properties(properties, object) do
        true -> :ok
        false -> :error
      end
    else
      :error
    end
  end

  def validate_properties(properties, object) do
    Enum.all?(properties, fn({key, value}) ->
      valid_property?(key, value, object)
    end)
  end

  def valid_property?("properties", prop_schema, object) do
    case Map.get(object, "properties") do
      nil -> true
      props ->
        case validate_properties(prop_schema, props) do
          true -> true
          false ->
            case prop_schema.unevaluatedProperties do
              true -> false
              false -> true
            end
        end
    end
  end

  def valid_property?(key, value, object) do
    case Map.get(object, key) do
      nil -> value.required == []
      prop ->
        case validate(value{properties: prop}) do
          :ok -> true
          :error ->
            case value.unevaluatedProperties do
              true -> false
              false -> true
            end
        end
    end
  end

  def valid_property?("required", required, object) do
    Enum.all?(required, fn(key) ->
      Map.has_key?(object, key)
    end)
  end

  def valid_property?(_, _, _), do: true
end

end
