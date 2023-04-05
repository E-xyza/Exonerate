defmodule :"additionalProperties-additionalProperties are allowed by default-gpt-3.5" do
  def validate(%{properties: props}) do
    validate_object(props)
  end

  def validate(_) do
    :error
  end

  defp validate_schema(schema, object) do
    schema(object)
  end

  defp validate_object(props) do
    map = Map.new()

    Enum.each(props, fn {key, value} ->
      Map.put(map, key, fn object -> object |> validate_schema(&validate_property(value, &1)) end)
    end)

    fn object when is_map(object) ->
      case Map.compare(object, map, :==) do
        :eq -> :ok
        :neq -> :error
      end
    end
  end

  defp validate_property(property, object) do
    case property do
      %{type: "object", properties: props} ->
        validate_object(props).(object)

      %{type: "string"} ->
        if is_binary(object) do
          :ok
        else
          :error
        end

      %{type: "integer"} ->
        if is_integer(object) do
          :ok
        else
          :error
        end

      _ ->
        :error
    end
  end
end
