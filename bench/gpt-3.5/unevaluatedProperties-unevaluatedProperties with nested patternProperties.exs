defmodule :"unevaluatedProperties-unevaluatedProperties with nested patternProperties-gpt-3.5" do
  @spec validate(map()) :: :ok | :error
  def validate(map) when is_map(map) do
    case types_valid?(map) and pattern_props_valid?(map) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp types_valid?(map) do
    case Map.fetch(map, "foo") do
      {:ok, value} -> is_binary(value)
      _ -> true
    end
  end

  defp pattern_props_valid?(map) do
    all_of =
      Map.get(
        map,
        "allOf"
      )

    case all_of do
      nil ->
        true

      _ ->
        types =
          all_of |> Enum.map(&Map.get(&1, "patternProperties", [])) |> Enum.map(&Map.keys(&1))

        Enum.all?(types, &is_binary/1)
    end
  end
end