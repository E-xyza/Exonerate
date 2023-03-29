defmodule :"$ref to boolean schema false" do
  
defmodule Validator do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_), do: :error
end

defmodule JsonSchema do
  def check_type(object, expected_type) do
    case is_map(object) do
      true ->
        case Map.get(object, "type") do
          actual_type when actual_type == expected_type ->
            :ok
          _ ->
            :error
        end
      _ ->
        :error
    end
  end

  def check_bool(object) do
    if check_type(object, "boolean") == :ok do
      case Map.get(object, "enum") do
        [false] ->
          :ok
        _ ->
          :error
      end
    else
      :error
    end
  end

  def check_definition(object, path) do
    case path do
      ["bool"] ->
        check_bool(object)
      [] ->
        :error
      [head | tail] ->
        if check_type(object, "object") == :ok do
          case Map.get(object, "properties") do
            props =
                %{
                  ^head := sub_schema
                } ->
              check_definition(sub_schema, tail)
            _ ->
              :error
          end
        else
          :error
        end
    end
  end

  def validate(schema), do: check_definition(schema, ["$ref"])
end

end
