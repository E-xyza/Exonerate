defmodule :"unevaluatedProperties with anyOf-gpt-3.5" do
  def validate(object) when is_map(object) do
    any_of_valid =
      object
      |> Map.keys()
      |> Enum.reduce(
        [],
        fn key, valid ->
          case any_of_key_valid?(key) do
            true -> [key | valid]
            false -> valid
          end
        end
      )

    case length(any_of_valid) do
      0 -> :error
      _ -> :ok
    end
  end

  def validate(_) do
    :error
  end

  defp any_of_key_valid?("foo") do
    map_key_valid?("foo", :string)
  end

  defp any_of_key_valid?("bar") do
    map_key_valid?("bar", :constant, "bar")
  end

  defp any_of_key_valid?("baz") do
    map_key_valid?("baz", :constant, "baz")
  end

  defp any_of_key_valid?("quux") do
    map_key_valid?("quux", :constant, "quux")
  end

  defp map_key_valid?(key, :string) do
    is_binary(Map.get(object, key))
  end

  defp map_key_valid?(key, :constant, val) do
    Map.get(object, key) === val
  end
end