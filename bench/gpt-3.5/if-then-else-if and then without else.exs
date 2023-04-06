defmodule :"if-then-else-if and then without else-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.fetch(object, "exclusiveMaximum") do
      {:ok, exclusive_max} when exclusive_max < 0 ->
        case Map.fetch(object, "minimum") do
          {:ok, min} when min >= -10 -> :ok
          _ -> :error
        end

      _ ->
        :ok
    end
  end

  def validate(_) do
    :error
  end
end