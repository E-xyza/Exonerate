defmodule :"minLength-minLength validation" do
  def validate(value) when is_binary(value) and byte_size(value) >= 2, do: :ok
  def validate(_), do: :error
end
