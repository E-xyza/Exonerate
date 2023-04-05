defmodule :"unevaluatedProperties-unevaluatedProperties with nested unevaluatedProperties" do
  def validate(object) when is_map(object) do
    foo_valid =
      case Map.fetch(object, "foo") do
        {:ok, value} -> is_binary(value)
        :error -> false
      end

    keys = Map.keys(object)
    unevaluated_props = Enum.reject(keys, &(&1 == "foo"))

    unevaluated_props_valid? =
      unevaluated_props
      |> Enum.all?(fn key ->
        case Map.fetch(object, key) do
          {:ok, value} -> is_binary(value) and byte_size(value) <= 2
          :error -> false
        end
      end)

    if foo_valid and unevaluated_props_valid?, do: :ok, else: :error
  end

  def validate(_), do: :error
end
