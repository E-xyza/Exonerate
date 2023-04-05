defmodule :"patternProperties validates properties matching a regex-gpt-3.5" do
  def validate(%{assoc: _} = object) when is_map(object) do
    case validate_pattern_properties(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_pattern_properties(object) do
    for {key, value} <- object do
      case Regex.run(~r/^f.*o$/, key) do
        nil -> true
        _ -> Integer.valid?(value)
      end
    end
    |> Enum.all?(fn x -> x == true end)
  end
end