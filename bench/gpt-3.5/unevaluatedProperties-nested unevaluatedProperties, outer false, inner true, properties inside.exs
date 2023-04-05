defmodule :"nested unevaluatedProperties, outer false, inner true, properties inside-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.keys(object) do
      [] -> :ok
      _ -> :error
    end
  end

  defp validate_array(array) do
    case array do
      [] ->
        :ok

      [head | tail] ->
        case validate_item(head) do
          :ok -> validate_array(tail)
          _ -> :error
        end
    end
  end

  defp validate_item(item) do
    case item do
      %{} -> validate_object(item)
      [] -> :ok
      [_ | _] -> validate_array(item)
      _ -> :ok
    end
  end
end
