defmodule :"items and subitems-gpt-3.5" do
  def validate(object) when is_list(object) do
    validate_items(
      object,
      []
    )
  end

  defp validate_items([], _) do
    :ok
  end

  defp validate_items([item | rest], acc) do
    case validate_item(item) do
      :ok -> validate_items(rest, acc ++ [:valid])
      :error -> :error
    end
  end

  defp validate_item(item) do
    case item do
      %{} = map -> validate_object(map)
      _ = other -> :error
    end
  end

  defp validate_object(object) do
    case object do
      %{"foo" => _} -> :ok
      _ -> :error
    end
  end
end