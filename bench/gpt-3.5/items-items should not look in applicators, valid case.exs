defmodule :"items-items should not look in applicators, valid case-gpt-3.5" do
  def validate(object) when is_map(object) do
    if validate_all_of(object) and validate_items(object) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_all_of(object) do
    all_of = ["allOf", [], [{"prefixItems", [], [{"minimum", 3, []}]}]]

    all(all_of, fn {key, [], value} ->
      case key do
        "prefixItems" -> validate_prefix_items(object, value)
        _ -> true
      end
    end)
  end

  defp validate_prefix_items(object, prefix_items) do
    Enum.all?(prefix_items, fn {key, _, value} ->
      case key do
        "minimum" -> validate_minimum(object, value)
        _ -> true
      end
    end)
  end

  defp validate_minimum(object, min) when is_integer(min) do
    if is_list(object) do
      length = length(object)
      length >= min
    else
      case Map.fetch(object, "length") do
        {:ok, length} -> length >= min
        :error -> false
      end
    end
  end

  defp validate_items(object) do
    items = ["items", [], {"minimum", 5, []}]

    case fetch_or_match_item(object, items) do
      :match -> true
      value -> validate_minimum(value, 5)
    end
  end

  defp all(list, fun) do
    Enum.all?(list, fun)
  end

  defp fetch_or_match_item(object, items) do
    case items do
      ["items", [], schema_value] ->
        case Map.fetch(object, "items") do
          {:ok, value} -> match(schema_value, value)
          :error -> :no_match
        end

      [key, [], child_items] ->
        case Map.fetch(object, key) do
          {:ok, value} ->
            case match(child_items, value) do
              :match -> :match
              _ -> validate(child_items, value)
            end

          :error ->
            :no_match
        end

      [key, child_key_values, child_items] ->
        case Map.fetch(object, key) do
          {:ok, value} ->
            case Map.fetch(value, child_key_values) do
              {:ok, child_value} ->
                case match(child_items, child_value) do
                  :match -> :match
                  _ -> validate(child_items, child_value)
                end

              :error ->
                :no_match
            end

          :error ->
            :no_match
        end
    end
  end

  defp match(schema_value, value) do
    case schema_value do
      [] ->
        :match

      [{key, [], []} | tail] ->
        case Map.has_key?(value, key) do
          true -> match(tail, value)
          false -> :no_match
        end

      [{key, child_key_values, []} | tail] ->
        case Map.fetch(value, key) do
          {:ok, child_value} ->
            case match(child_key_values, child_value) do
              :match -> match(tail, value)
              _ -> :no_match
            end

          :error ->
            :no_match
        end

      _ ->
        :no_match
    end
  end
end