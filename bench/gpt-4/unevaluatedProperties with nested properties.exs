defmodule :"unevaluatedProperties with nested properties" do
  def validate(object) when is_map(object) do
    keys = Map.keys(object)

    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    bar_valid =
      case Map.fetch(object, "bar") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    unevaluated_props = Enum.reject(keys, &(&1 in ["foo", "bar"]))

    if foo_valid and bar_valid and Enum.empty?(unevaluated_props), do: :ok, else: :error
  end

  def validate(_), do: :error
end
