defmodule :"properties, patternProperties, additionalProperties interaction-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_properties(object) do
      :error ->
        :error

      _ ->
        case validate_pattern_properties(object) do
          :error -> :error
          _ -> :ok
        end
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(object) do
    properties = object |> Map.keys() |> Enum.filter(fn key -> key in ["bar", "foo"] end)

    valid =
      Enum.all?(properties, fn key ->
        case key do
          "bar" -> validate_array(object[key], "integer")
          "foo" -> validate_array(object[key], "integer", max_items: 3)
        end
      end)

    if valid do
      :ok
    else
      :error
    end
  end

  defp validate_pattern_properties(object) do
    pattern_properties =
      object |> Map.keys() |> Enum.filter(fn key -> String.match?(key, ~r/f\.o\d*/) end)

    valid =
      Enum.reduce(pattern_properties, true, fn key, acc ->
        case acc do
          false ->
            false

          true ->
            case validate_array(object[key], "integer", min_items: 2) do
              :error -> false
              _ -> true
            end
        end
      end)

    if valid do
      :ok
    else
      :error
    end
  end

  defp validate_array(array, type, opts \\ []) do
    valid =
      case Keyword.get(opts, :max_items) do
        nil -> true
        max_items -> length(array) <= max_items
      end

    if valid do
      case Keyword.get(opts, :min_items) do
        nil ->
          :ok

        min_items ->
          if length(array) >= min_items do
            :ok
          else
            :error
          end
      end
    else
      :error
    end
  end
end