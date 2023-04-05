defmodule :"allOf-allOf with the last empty schema" do
  
defmodule Validator do
  def validate(value) do
    case value do
      %{__all_of__: [subschema | _]} ->
        validate_all_of(subschema, value)
      %{type: "number"} ->
        validate_number(value)
      %{type: "object"} ->
        validate_object(value)
      %{type: "array"} ->
        validate_array(value)
      _ -> :error
    end
  end

  defp validate_all_of(subschema, value) do
    case Validator.validate(subschema) do
      :ok ->
        case Validator.validate(Map.delete(value, :__all_of__)) do
          :ok -> :ok
          _ -> :error
        end
      _ -> :error
    end
  end

  defp validate_number(%{type: type}), when type in ["integer", "number"] do
    :ok
  end
  defp validate_number(_), do: :error

  defp validate_object(%{type: "object"}) do
    :ok
  end
  defp validate_object(_), do: :error

  defp validate_array(%{type: "array"}) do
    :ok
  end
  defp validate_array(_), do: :error
end

end
