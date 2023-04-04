defmodule :"unevaluatedProperties with oneOf" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    bar_valid = Map.has_key?(object, "bar") and object["bar"] == "bar"
    baz_valid = Map.has_key?(object, "baz") and object["baz"] == "baz"

    one_of_valid = (bar_valid and not baz_valid) or (baz_valid and not bar_valid)

    unevaluated_props = Map.keys(object) -- ["foo", "bar", "baz"]

    unevaluated_props_valid? = Enum.empty?(unevaluated_props)

    if foo_valid and one_of_valid and unevaluated_props_valid?, do: :ok, else: :error
  end

  def validate(_), do: :error
end
