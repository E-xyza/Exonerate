defmodule :"anyOf-anyOf complex types-gpt-3.5" do
  def validate(%{"bar" => bar}) when is_integer(bar) do
    :ok
  end

  def validate(%{"foo" => foo}) when is_binary(foo) do
    :ok
  end

  def validate(_) do
    :error
  end
end