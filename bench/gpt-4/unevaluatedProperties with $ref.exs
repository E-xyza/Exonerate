defmodule :"unevaluatedProperties with $ref" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.get(object, "foo") do
        value when is_binary(value) -> true
        _ -> false
      end

    bar_valid =
      case Map.get(object, "bar") do
        value when is_binary(value) -> true
        _ -> false
      end

    unevaluated_props = Map.drop(object, ["foo", "bar"])

    if foo_valid and bar_valid and Enum.empty?(unevaluated_props), do: :ok, else: :error
  end

  def validate(_), do: :error
end
