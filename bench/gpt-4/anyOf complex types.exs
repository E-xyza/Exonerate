defmodule :"anyOf complex types" do
  def validate(%{"bar" => bar}) when is_integer(bar), do: :ok
  def validate(%{"foo" => foo}) when is_binary(foo), do: :ok
  def validate(_), do: :error
end
