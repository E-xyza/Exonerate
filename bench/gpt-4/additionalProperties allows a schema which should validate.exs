defmodule :"additionalProperties allows a schema which should validate" do
  def validate(object) when is_map(object) do
    keys = Map.keys(object)

    valid? =
      Enum.all?(keys, fn key ->
        case key do
          "bar" -> true
          "foo" -> true
          _ -> is_boolean(Map.get(object, key))
        end
      end)

    if valid?, do: :ok, else: :error
  end

  def validate(_), do: :error

  defp is_boolean(value), do: value in [true, false]
end
