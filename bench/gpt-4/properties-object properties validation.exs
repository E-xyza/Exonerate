defmodule :"properties-object properties validation" do
  def validate(%{"foo" => foo, "bar" => bar}) when is_integer(foo) and is_binary(bar), do: :ok

  def validate(%{"foo" => foo}) when is_integer(foo), do: :ok

  def validate(%{"bar" => bar}) when is_binary(bar), do: :ok

  def validate(%{}), do: :ok

  def validate(_), do: :error
end
