defmodule :"unevaluatedProperties-unevaluatedProperties with nested unevaluatedProperties-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_properties(object) do
      :error -> :error
      _ -> validate_unevaluated_properties(object)
    end
  end

  def validate(_) do
    :error
  end

  def validate_properties(object) do
    case is_map(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate_unevaluated_properties(object) do
    case Map.keys(object) |> Enum.filter(&is_binary/1) |> Enum.take(3) do
      [] -> :ok
      [_] -> :ok
      _ -> :error
    end
  end
end