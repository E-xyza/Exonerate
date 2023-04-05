defmodule :"contains-items + contains-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_contains(object) do
      :ok ->
        case validate_items(object) do
          :ok -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def validate(object) do
    :error
  end

  defp validate_contains(object) do
    case Map.get(object, "contains") do
      nil ->
        :ok

      contains ->
        case Map.get(contains, "multipleOf") do
          nil ->
            :ok

          multiple_of ->
            if rem(Map.size(object), multiple_of) == 0 do
              :ok
            else
              :error
            end
        end
    end
  end

  defp validate_items(object) do
    case Map.get(object, "items") do
      nil ->
        :ok

      items ->
        case Map.get(items, "multipleOf") do
          nil ->
            :ok

          multiple_of ->
            if Enum.all?(Map.keys(object), fn x -> rem(x, multiple_of) == 0 end) do
              :ok
            else
              :error
            end
        end
    end
  end
end
