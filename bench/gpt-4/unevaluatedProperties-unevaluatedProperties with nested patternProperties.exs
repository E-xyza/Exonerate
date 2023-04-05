defmodule :"unevaluatedProperties-unevaluatedProperties with nested patternProperties" do
  def validate(object) when is_map(object) do
    keys = Map.keys(object)

    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    bar_valid =
      Enum.all?(keys, fn key ->
        if String.starts_with?(key, "bar") do
          case Map.fetch(object, key) do
            {:ok, value} -> is_binary(value)
            :error -> false
          end
        else
          true
        end
      end)

    unevaluated_props =
      Enum.reject(keys, fn key ->
        key == "foo" or String.starts_with?(key, "bar")
      end)

    if foo_valid and bar_valid and Enum.empty?(unevaluated_props), do: :ok, else: :error
  end

  def validate(_), do: :error
end
