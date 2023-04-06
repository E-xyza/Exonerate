defmodule :"contains-contains keyword with boolean schema true-gpt-3.5" do
  def validate(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, decoded} -> validate(decoded)
      _ -> :error
    end
  end

  def validate(json) when is_map(json) do
    case Map.has_key?(json, "contains") do
      true -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end