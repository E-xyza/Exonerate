defmodule :"unevaluatedProperties-unevaluatedProperties with dependentSchemas" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.has_key?(object, "foo") do
        true ->
          is_binary(object["foo"]) and Map.has_key?(object, "bar") and object["bar"] == "bar"

        _ ->
          true
      end

    unevaluated_props = Map.keys(object) -- ["foo", "bar"]
    if foo_valid and Enum.empty?(unevaluated_props), do: :ok, else: :error
  end

  def validate(_), do: :error
end
