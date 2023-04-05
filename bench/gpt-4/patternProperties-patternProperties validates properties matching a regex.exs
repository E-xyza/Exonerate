defmodule :"patternProperties-patternProperties validates properties matching a regex" do
  def validate(object) when is_map(object) do
    case object |> Map.keys() |> Enum.filter(fn k -> Regex.match?(~r/f.*o/, k) end) |> Enum.all?(fn k -> is_integer(object[k]) end) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_), do: :error
end
