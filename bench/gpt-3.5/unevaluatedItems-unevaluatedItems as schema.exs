defmodule :"unevaluatedItems-unevaluatedItems as schema-gpt-3.5" do
  def validate(array) when is_list(array) do
    case Enum.find_index(array, fn item -> not is_binary(item) end) do
      nil -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end