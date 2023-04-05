defmodule :"nul characters in strings-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.fetch(object, "enum") do
      {:ok, ["hello\0there"]} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end