defmodule :"unevaluatedItems-unevaluatedItems true-gpt-3.5" do
  def validate(array) when is_list(array) do
    case Enum.find_index(array, fn _ -> false end) do
      nil -> :ok
      index -> {:error, "element at index #{index} is not allowed by the schema"}
    end
  end

  def validate(_) do
    {:error, "expected an array with unevaluated items"}
  end
end