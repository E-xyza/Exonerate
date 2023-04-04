defmodule :"a schema given for items-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_map(object)
  end

  def validate(_) do
    :error
  end

  defp validate_map(map) do
    case Map.keys(map) do
      [:items] -> validate_items(map[:items])
      _ -> :error
    end
  end

  defp validate_items(schema) do
    case schema do
      %{"type" => "integer"} -> :ok
      _ -> :error
    end
  end
end
