defmodule :"ref-relative pointer ref to object-gpt-3.5" do
  def validate(json) when is_map(json) do
    validate_map(json, %{"$": nil})
  end

  def validate(_, _) do
    :error
  end

  defp validate_map(%{} = map, pointers) do
    case validate_pointers(pointers) do
      [] -> :ok
      errors -> :error
    end
  end

  defp validate_map(map, pointers) do
    for {key, value} <- map do
      case Map.has_key?(pointers, key) do
        true ->
          case validate_pointer(key, value, pointers) do
            :ok -> validate_map(value, pointers)
            :error -> :error
          end

        false ->
          case validate_key(key, pointers) do
            :ok -> validate_map(value, pointers)
            :error -> :error
          end
      end
    end
  end

  defp validate_pointers(pointers) do
    pointers
    |> Map.to_list()
    |> Enum.map(
      &elem(
        &1,
        0
      )
    )
    |> Enum.filter_not(&is_map(Map.get(pointers, &1)))
    |> Enum.map(fn pointer -> {:error, "Pointer #{pointer} not found"} end)
  end

  defp validate_key(key, pointers) do
    case key do
      "$ref" ->
        case Map.get(pointers, "$") do
          %{"properties" => properties} ->
            %{pointer | ref} =
              Map.get(
                pointers,
                "$ref"
              )

            case List.wrap(ref) do
              [{"#", "properties"} | rest] ->
                validate_pointer("properties", properties, Map.put(pointers, "$", pointer))

              _ ->
                :error
            end

          _ ->
            :error
        end

      _ ->
        :ok
    end
  end

  defp validate_pointer(key, value, pointers) do
    case key do
      "$ref" ->
        ref = value |> URI.parse() |> access(:path, 0)

        case ref do
          nil ->
            :error

          "" ->
            :ok

          _ ->
            ref
            |> String.split("/")
            |> validate_pointer_ref(
              rest(pointers),
              []
            )
        end

      _ ->
        :ok
    end
  end

  defp validate_pointer_ref(pointers, _) when is_nil(pointers) do
    [:error]
  end

  defp validate_pointer_ref(pointers, []) do
    case Map.get(pointers, hd(rest(keys(pointers)))) do
      %{"properties" => properties} ->
        validate_pointer_ref(Map.put(pointers, hd(rest(keys(pointers))), %{"$": nil}), properties)

      nil ->
        [:error]

      _ ->
        [:ok]
    end
  end

  defp validate_pointer_ref(pointers, [key | rest_keys]) do
    case Map.get(pointers, key) do
      nil ->
        [:error]

      value ->
        case validate_pointer_ref(value, rest_keys) do
          [:ok] -> [:ok]
          _ -> [:error]
        end
    end
  end
end