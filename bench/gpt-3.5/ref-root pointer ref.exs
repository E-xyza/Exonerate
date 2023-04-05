defmodule :"root pointer ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate(object, {"additionalProperties", false}, {"properties", %{"foo" => {"$ref", "#"}}})
  end

  def validate(_) do
    :error
  end

  defp validate(object, {key, value}, schema) when is_map(object) do
    case Map.has_key?(object, key) do
      true ->
        case value do
          false ->
            case Map.keys(object) -- [key] do
              [] -> :ok
              _ -> :error
            end

          {k, v} ->
            case Map.fetch(object, k, :invalid) do
              v -> validate(v, v, schema)
              _ -> :error
            end

          _ ->
            :error
        end

      false ->
        case value do
          true -> :ok
          _ -> :error
        end
    end
  end

  defp validate(object, {key, value}, %{"$ref" => "#"} = schema) when is_map(object) do
    case Map.has_key?(object, key) do
      true ->
        case value do
          false ->
            case Map.keys(object) -- [key] do
              [] -> :ok
              _ -> :error
            end

          {k, v} ->
            case Map.fetch(object, k, :invalid) do
              v -> validate(v, v, schema)
              _ -> :error
            end

          _ ->
            :error
        end

      false ->
        case value do
          true -> validate(object, {"type", "object"}, schema)
          _ -> :error
        end
    end
  end

  defp validate(object, {key, value}, %{"$ref" => ref} = schema) when is_map(object) do
    case Map.has_key?(object, key) do
      true ->
        case value do
          false ->
            case Map.keys(object) -- [key] do
              [] -> :ok
              _ -> :error
            end

          _ ->
            validate(object, {key, value}, ref_to_schema(ref))
        end

      false ->
        case value do
          true -> validate(object, {"type", "object"}, schema)
          _ -> :error
        end
    end
  end

  defp validate(_object, _key_value, _schema) do
    :error
  end

  defp ref_to_schema(ref) do
    ref_parts =
      String.split(
        ref,
        "#"
      )

    case ref_parts do
      [_ | ""] ->
        %{}

      [_ | refs] ->
        refs
        |> String.split("/")
        |> Enum.reject(&(&1 == ""))
        |> Enum.reduce(
          {"", %{}},
          fn segment, {current_path, current_map} ->
            case Map.has_key?(current_map, segment) do
              true ->
                {current_path <> "/" <> segment, Map.get(current_map, segment)}

              false ->
                case segment do
                  "-" ->
                    {current_path <> "/-", []}

                  _ ->
                    case String.to_integer(segment) do
                      {:error, _} ->
                        throw(%ArgumentError{message: "Invalid JSON pointer path: #{ref}"})

                      index ->
                        {current_path <> "/#{segment}", Enum.at(current_map, index)}
                    end
                end
            end
          end
        )
        |> elem(1)
    end
  end
end