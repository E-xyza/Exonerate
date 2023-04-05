defmodule :"unevaluatedProperties schema-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object) |> Enum.filter(fn k -> is_binary(k) && String.length(k) < 3 end) do
      [] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end