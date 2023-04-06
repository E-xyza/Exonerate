defmodule :"maxContains-maxContains with contains-gpt-3.5" do
  def(validate(object) when is_map(object), do: case(validate_object(object))) do
    true -> :ok
    false -> :error
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case Map.fetch(object, "contains") do
      {:ok, contains} ->
        case Map.fetch(object, "maxContains") do
          {:ok, max_contains} -> contains |> Enum.count(&(&1 == 1)) <= max_contains
          :error -> true
        end

      :error ->
        true
    end
  end
end