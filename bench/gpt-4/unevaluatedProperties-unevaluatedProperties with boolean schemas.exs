defmodule :"unevaluatedProperties-unevaluatedProperties with boolean schemas" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.get(object, "foo") do
        value when is_binary(value) -> true
        _ -> false
      end

    unevaluated_props = Map.delete(object, "foo")

    if foo_valid and Enum.empty?(unevaluated_props), do: :ok, else: :error
  end

  def validate(_), do: :error
end
