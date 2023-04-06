defmodule :"dependentSchemas-single dependency-gpt-3.5" do
  def validate(%{"bar" => %{"foo" => foo_val, "bar" => bar_val}} = object)
      when is_map(object) and is_integer(foo_val) and is_integer(bar_val) do
    :ok
  end

  def validate(_) do
    :error
  end
end