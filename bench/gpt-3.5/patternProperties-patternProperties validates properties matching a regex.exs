defmodule :"patternProperties-patternProperties validates properties matching a regex-gpt-3.5" do
    def validate(object) when is_map(object) do
      case Map.keys(object) do
        keys when all_match?(keys, &match?(&1, ~r/f.*o/)) -> :ok
        _ -> :error
      end
    end

    def validate(_) do
      :error
    end

    defp all_match?([], _) do
      true
    end

    defp all_match?([h | t], regex) do
      match?(h, regex) and all_match?(t, regex)
    end
end
