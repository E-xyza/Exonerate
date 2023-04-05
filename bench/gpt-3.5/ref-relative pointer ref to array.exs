defmodule :"relative pointer ref to array-gpt-3.5" do
  def validate(json) when is_map(json) do
    validate_object(json)
  end

  def validate(json) do
    :error
  end

  defp validate_object(json) do
    case json["prefixItems"] do
      nil ->
        :error

      [first | _] ->
        case first["type"] do
          "integer" -> validate_ref(json, first)
          _ -> :error
        end
    end
  end

  defp validate_ref(json, ref) do
    case ref["$ref"] do
      nil ->
        :ok

      "#/prefixItems/0" ->
        case json["prefixItems"] do
          [_, item | _] -> validate(json, item)
          _ -> :error
        end

      _ ->
        :error
    end
  end
end
