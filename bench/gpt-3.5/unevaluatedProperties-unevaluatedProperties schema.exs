defmodule :"unevaluatedProperties-unevaluatedProperties schema-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object)
         |> Enum.filter(fn key -> is_binary(key) end)
         |> Enum.filter(fn key -> String.length(key) >= 3 end) do
      [] -> :error
      _ -> :ok
    end
  end

  def validate(_) do
    :error
  end
end