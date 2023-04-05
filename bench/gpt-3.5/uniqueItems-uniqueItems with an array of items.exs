defmodule :"uniqueItems with an array of items-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_map(object)
  end

  def validate(object) when is_list(object) do
    validate_list(object)
  end

  def validate(_) do
    :error
  end

  defp validate_map(map) do
    :ok =
      ensure_keys(
        map,
        [:prefixItems, :uniqueItems]
      )

    prefix_items = map[:prefixItems]
    unique_items = map[:uniqueItems]

    case prefix_items do
      [] ->
        :ok

      _ ->
        prefix_type = get_type(prefix_items)

        case prefix_type do
          :boolean ->
            length = length(prefix_items)

            if length == 2 and unique_items do
              :ok
            else
              :error
            end
        end
    end
  end

  defp validate_list(list) do
    :error
  end

  defp ensure_keys(map, keys) do
    for key <- keys do
      unless Map.has_key?(map, key) do
        raise ArgumentError, message: "Missing key '#{key}' in map"
      end
    end

    :ok
  end

  defp get_type(items) do
    type = nil

    for item <- items do
      unless Map.has_key?(item, :type) do
        raise ArgumentError, message: "Missing type key in item: #{inspect(item)}"
      end

      item_type = item[:type]

      if type and item_type != type do
        raise ArgumentError,
          message: "Inconsistent type in prefixItems"
      end

      type = item_type
    end

    type
  end
end