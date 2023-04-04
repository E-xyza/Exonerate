defmodule :"items should not look in applicators, valid case-gpt-3.5" do
  def validate(%{"allOf" => [prefix_items], "items" => items} = data) do
    case validate_prefix_items(prefix_items, data) do
      :ok -> validate_items(items)
      error -> error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_prefix_items(%{"prefixItems" => prefix_items}, data) do
    Enum.all?(prefix_items, &validate_constraint(&1, data))
  end

  defp validate_prefix_items(_, _) do
    :ok
  end

  defp validate_items(%{"minimum" => min} = items) do
    case items do
      %{"type" => "array"} ->
        fn data ->
          case Enum.count(data) >= min do
            true -> :ok
            false -> :error
          end
        end

      _ ->
        fn data ->
          case data >= min do
            true -> :ok
            false -> :error
          end
        end
    end
  end

  defp validate_items(_, _) do
    :ok
  end

  defp validate_constraint(%{"minimum" => min}, data) do
    case data do
      %{"type" => "array"} -> Enum.all?(data, &(&1 >= min))
      _ -> data >= min
    end
  end

  defp validate_constraint(_, _) do
    :ok
  end
end
