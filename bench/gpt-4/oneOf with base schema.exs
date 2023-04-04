defmodule :"oneOf with base schema" do
  def validate(value) do
    case value do
      v when is_binary(v) and byte_size(v) >= 2 and byte_size(v) <= 4 -> :ok
      v when is_integer(v) and v >= 2 -> :ok
      _ -> :error
    end
  end
end
