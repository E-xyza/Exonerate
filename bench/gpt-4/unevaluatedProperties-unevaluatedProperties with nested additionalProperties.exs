defmodule :"unevaluatedProperties-unevaluatedProperties with nested additionalProperties" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    keys = Map.keys(object)
    unevaluated_props = Enum.reject(keys, &(&1 == "foo"))

    if foo_valid and Enum.empty?(unevaluated_props), do: :ok, else: :error
  end

  def validate(_), do: :error
end
