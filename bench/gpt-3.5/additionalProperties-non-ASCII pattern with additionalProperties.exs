defmodule :"additionalProperties-non-ASCII pattern with additionalProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object) do
      keys when all_keys_are_ascii?(keys) -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp all_keys_are_ascii?(keys) do
    Enum.all?(keys, &is_ascii/1) and Enum.all?(keys, &(String.match?(&1, ~r/^á/) == false))
  end
end