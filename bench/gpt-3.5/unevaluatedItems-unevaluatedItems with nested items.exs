defmodule :"unevaluatedItems-unevaluatedItems with nested items-gpt-3.5" do
  def validate(array) when is_list(array) do
    case validate_items(array) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_items(items) do
    Enum.all?(items, fn item ->
      case item do
        %{"type" => "string"} -> true
        _ -> false
      end
    end)
  end
end