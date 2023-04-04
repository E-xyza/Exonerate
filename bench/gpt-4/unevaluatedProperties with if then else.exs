defmodule :"unevaluatedProperties with if/then/else" do
  def validate(object) when is_map(object) do
    if_condition = Map.get(object, "foo") == "then"

    then_valid =
      case if_condition do
        true ->
          required_bar = Map.has_key?(object, "bar")
          bar_valid = required_bar and is_binary(object["bar"])
          unevaluated_props_then = Map.keys(object) -- ["foo", "bar"]
          required_bar and bar_valid and Enum.empty?(unevaluated_props_then)

        _ ->
          false
      end

    else_valid =
      case if_condition do
        false ->
          required_baz = Map.has_key?(object, "baz")
          baz_valid = required_baz and is_binary(object["baz"])
          unevaluated_props_else = Map.keys(object) -- ["foo", "baz"]
          required_baz and baz_valid and Enum.empty?(unevaluated_props_else)

        _ ->
          false
      end

    if then_valid or else_valid, do: :ok, else: :error
  end

  def validate(_), do: :error
end
