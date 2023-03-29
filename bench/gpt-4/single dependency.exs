defmodule :"single dependency" do
  def validate(object) when is_map(object) do
    if is_dependent_schema_valid?(object) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp is_dependent_schema_valid?(object) do
    case Map.get(object, "bar") do
      nil -> true
      _ -> is_bar_dependency_valid?(object)
    end
  end

  defp is_bar_dependency_valid?(object) do
    foo_value = Map.get(object, "foo")
    bar_value = Map.get(object, "bar")

    is_integer(foo_value) and is_integer(bar_value)
  end
end
