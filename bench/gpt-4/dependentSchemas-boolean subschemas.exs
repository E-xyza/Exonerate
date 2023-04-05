defmodule :"dependentSchemas-boolean subschemas" do
  def validate(object) when is_map(object) do
    if is_dependencies_valid?(object) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp is_dependencies_valid?(object) do
    is_foo_dependency_valid?(object) and is_bar_dependency_valid?(object)
  end

  defp is_foo_dependency_valid?(object) do
    case Map.get(object, "foo") do
      nil -> true
      _ -> true
    end
  end

  defp is_bar_dependency_valid?(object) do
    case Map.get(object, "bar") do
      nil -> true
      _ -> false
    end
  end
end
