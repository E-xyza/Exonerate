defmodule :"type-multiple types can be specified in an array-gpt-3.5" do
  def validate(value) do
    case value do
      _ when is_integer(value) or is_binary(value) -> :ok
      _ -> :error
    end
  end
end
