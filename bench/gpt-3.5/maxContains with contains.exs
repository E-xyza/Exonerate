defmodule :"maxContains with contains-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_contains(object, 1) do
      :ok ->
        case validate_max_contains(object, 1) do
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

  defp validate_contains(object, const) do
    if Map.values(object) |> Enum.count(&(&1 == const)) == 1 do
      :ok
    else
      :error
    end
  end

  defp validate_max_contains(object, max_count) do
    if Map.values(object) |> Enum.count(&(&1 == 1)) <= max_count do
      :ok
    else
      :error
    end
  end
end
