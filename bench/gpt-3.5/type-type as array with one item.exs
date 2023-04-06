defmodule :"type-type as array with one item-gpt-3.5" do
  def validate(value) do
    case value do
      [item] when is_binary(item) -> :ok
      _ -> :error
    end
  end
end