defmodule :"uniqueItems-uniqueItems with an array of items and additionalItems=false-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.fetch(object, "items") do
      {:ok, false} ->
        case Map.fetch(object, "prefixItems") do
          {:ok, prefix_items} ->
            if is_unique_items(prefix_items) do
              :ok
            else
              :error
            end

          :error ->
            :error
        end

      :error ->
        :error
    end
  end

  defp is_unique_items(items) do
    list_of_types = Enum.map(items, &Map.fetch(&1, "type", nil))
    length_before = length(list_of_types)
    length_after = length(list_of_types |> Enum.uniq())
    length_before == length_after
  end
end