defmodule :"unevaluatedProperties-unevaluatedProperties can't see inside cousins" do
  def validate(object) when is_map(object) do
    # Check if "foo" exists in the object
    foo_exists = Map.has_key?(object, "foo")

    # Check for unevaluated properties (excluding "foo")
    unevaluated_props = Map.drop(object, ["foo"])

    if foo_exists and Enum.empty?(unevaluated_props), do: :ok, else: :error
  end

  def validate(_), do: :error
end
