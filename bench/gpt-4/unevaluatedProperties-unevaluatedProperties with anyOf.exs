defmodule :"unevaluatedProperties-unevaluatedProperties with anyOf" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    bar_valid = Map.has_key?(object, "bar") and object["bar"] == "bar"
    baz_valid = Map.has_key?(object, "baz") and object["baz"] == "baz"
    quux_valid = Map.has_key?(object, "quux") and object["quux"] == "quux"

    any_of_valid = bar_valid or baz_valid or quux_valid

    unevaluated_props = Map.keys(object) -- ["foo", "bar", "baz", "quux"]

    unevaluated_props_valid? = Enum.empty?(unevaluated_props)

    if foo_valid and any_of_valid and unevaluated_props_valid?, do: :ok, else: :error
  end

  def validate(_), do: :error
end
