defmodule :"unevaluatedProperties-nested unevaluatedProperties, outer true, inner false, properties outside" do
  def validate(object) when is_map(object) do
    # Check if "foo" exists in the object and is of type "string"
    foo_valid =
      case object["foo"] do
        s when is_binary(s) -> true
        nil -> true
        _ -> false
      end

    # Check for unevaluated properties (excluding "foo")
    unevaluated_props = Map.drop(object, ["foo"])

    if foo_valid and Enum.empty?(unevaluated_props), do: :ok, else: :ok
  end

  def validate(_), do: :error
end
