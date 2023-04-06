defmodule :"ref-naive replacement of $ref with its destination is not correct-gpt-3.5" do
  def validate(%{"enum" => [{"$ref" => "#/$defs/a_string"}]}) do
    {:ok, %{"$defs" => %{"a_string" => %{"type" => "string"}}}} |> validate
  end

  def validate(%{"type" => "object"}) do
    fn object when is_map(object) -> :ok
       _ -> :error
    end
  end

  def validate(_), do: :error

  defp validate(schema, object)
         when is_map(schema) and is_map(object) do
    case schema do
      %{"allOf" => schemas} ->
        case Enum.reduce(schemas, :ok, fn sub_schema, :ok ->
                                              validate(sub_schema, object)
                                            (_, errors) -> errors
                                          end) do
          :error -> :error
          _ -> :ok
        end
      %{"properties" => properties} ->
        case Enum.reduce(properties, :ok, fn {key, sub_schema}, :ok ->
                                                     case Map.get(object, key) do
                                                       nil -> :error
                                                       val -> validate(sub_schema, val)
                                                     end
                                                   (_, errors) -> errors
                                                 end) do
          :error -> :error
          _ -> :ok
        end
      %{"required" => required} ->
        case Enum.reduce(required, :ok, fn key, :ok ->
                                              case Map.get(object, key) do
                                                nil -> :error
                                                val -> :ok
                                              end
                                            (_, errors) -> errors
                                          end) do
          :error -> :error
          _ -> :ok
        end
      %{"type" => "array", "items" => sub_schema} ->
        case object do
          [] -> :ok
          [val | rest] -> validate(sub_schema, val) |> validate(rest)
          _ -> :error
        end
      %{"$defs" => defs} -> validate(%{"properties" => defs}, object)
      _ -> :error
    end
  end

  defp validate(schema, object)
         when is_list(schema) and is_list(object) do
    case schema do
      [sub_schema] -> validate(sub_schema, object)
      _ -> :error
    end
  end

  defp validate(schema, object), do: :error
end
