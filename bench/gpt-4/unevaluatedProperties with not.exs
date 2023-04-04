defmodule :"unevaluatedProperties with not" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    not_bar_valid = not (Map.has_key?(object, "bar") and object["bar"] == "bar")

    unevaluated_props = Map.keys(object) -- ["foo", "bar"]

    unevaluated_props_valid? = Enum.empty?(unevaluated_props)

    if foo_valid and not_bar_valid and unevaluated_props_valid?, do: :ok, else: :error
  end

  def validate(_), do: :error
end
