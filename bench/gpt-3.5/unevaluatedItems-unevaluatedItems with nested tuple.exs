defmodule :"unevaluatedItems-unevaluatedItems with nested tuple-gpt-3.5" do
  def validate(json) when is_list(json) do
    case validate_items(json) do
      :ok ->
        case validate_prefix_items(json) do
          :ok -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_items(json) do
    case Keyword.get(json, "type") do
      "array" ->
        case Keyword.get(json, "unevaluatedItems", true) do
          false ->
            {prefix_items, all_of} = extract_items(json)
            validate_all_of_items(prefix_items, all_of, [])

          _ ->
            :ok
        end

      _ ->
        :error
    end
  end

  defp extract_items(json) do
    prefix_items = Keyword.get(json, "prefixItems", [])
    all_of = Keyword.get(json, "allOf", [])
    {prefix_items, all_of}
  end

  defp validate_all_of_items(prefix_items, all_of, acc) do
    case all_of do
      [] ->
        validate_prefix_items(prefix_items, acc)

      [current_item | rest] ->
        case validate_prefix_items(current_item, acc) do
          :ok -> validate_all_of_items(prefix_items, rest, [current_item | acc])
          _ -> :error
        end
    end
  end

  defp validate_prefix_items(json, all_of) do
    case json do
      {"type", "array"} ->
        case Keyword.get(json, "unevaluatedItems") do
          false -> validate_items(json)
          _ -> :ok
        end

      {"type", type} ->
        Enum.each(all_of, fn item ->
          case Keyword.get(item, "type") do
            nil -> :ok
            type -> :ok
            _ -> :error
          end
        end)

        :ok

      _ ->
        :error
    end
  end
end