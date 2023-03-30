defmodule :"multiple dependents required" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "quux") do
      true ->
        deps = Map.take(object, ["foo", "bar", "quux"])
        case Enum.all?(deps, fn {key, _} -> Map.has_key?(object, key) end) do
          true -> :ok
          false -> :error
        end
      false -> :ok
    end
  end

  def validate(_), do: :error
end
