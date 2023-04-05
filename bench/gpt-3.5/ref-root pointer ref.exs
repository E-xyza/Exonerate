defmodule :"ref-root pointer ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.has_key?(object, "foo") do
      true ->
        sub_schema =
          Map.get(
            object,
            "foo"
          )

        case validate_subobject(sub_schema) do
          :ok -> :ok
          _ -> :error
        end

      false ->
        :ok
    end
  end

  defp validate_subobject(object) do
    case Map.get(object, "$ref") do
      "#object" -> validate_object(object)
      _ -> :error
    end
  end
end
