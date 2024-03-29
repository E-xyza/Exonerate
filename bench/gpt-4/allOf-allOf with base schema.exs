defmodule :"allOf-allOf with base schema" do
  def validate(object) when is_map(object) do
    has_foo = Map.has_key?(object, "foo") and is_binary(object["foo"])
    has_baz = Map.has_key?(object, "baz") and is_nil(object["baz"])
    has_bar = Map.has_key?(object, "bar") and is_integer(object["bar"])

    if has_foo and has_baz and has_bar do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
