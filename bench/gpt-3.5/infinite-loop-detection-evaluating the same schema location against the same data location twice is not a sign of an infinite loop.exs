defmodule :"evaluating the same schema location against the same data location twice is not a sign of an infinite loop-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_all_of(object, schema())
  end

  def validate(_) do
    :error
  end

  defp schema do
    %{
      "$defs" => %{"int" => %{"type" => "integer"}},
      "allOf" => [
        %{"properties" => %{"foo" => %{"$ref" => "#/$defs/int"}}},
        %{"additionalProperties" => %{"$ref" => "#/$defs/int"}}
      ]
    }
  end

  defp validate_all_of(object, %{"allOf" => all_of, "$defs" => defs}) do
    case Enum.all?(all_of, &validate_one_of(object, &1, defs)) do
      true -> :ok
      _ -> :error
    end
  end

  defp validate_one_of(object, %{"properties" => properties}, defs) do
    Enum.all?(
      for {key, schema} <- properties do
        validate_property(object[key], schema, defs)
      end
    )
  end

  defp validate_one_of(object, %{"additionalProperties" => schema}, defs) do
    Enum.all?(Map.values(object), &validate_property(&1, schema, defs))
  end

  defp validate_property(value, %{"$ref" => ref}, defs) do
    schema = get_schema(ref, defs)

    case schema do
      nil -> true
      _ -> validate_all_of(value, schema)
    end
  end

  defp validate_property(value, %{"type" => "integer"}, _) do
    is_integer(value)
  end

  defp get_schema(ref, %{"$defs" => defs} = current_schema) do
    ref
    |> String.split("/")
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce(current_schema, fn
      key, %{"$ref" => ref} -> get_schema(ref, defs[key])
      key, other -> other |> Map.get(key)
    end)
  end
end