defmodule :"dependencies with escaped characters" do
  def validate(object) when is_map(object) do
    if is_dependencies_valid?(object) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp is_dependencies_valid?(object) do
    is_foo_tab_bar_dependency_valid?(object) and is_foo_quote_bar_dependency_valid?(object)
  end

  defp is_foo_tab_bar_dependency_valid?(object) do
    case Map.get(object, "foo\tbar") do
      nil -> true
      value -> Enum.count(value) >= 4
    end
  end

  defp is_foo_quote_bar_dependency_valid?(object) do
    case Map.get(object, "foo'bar") do
      nil -> true
      value -> Enum.member?(Map.keys(value), "foo\"bar")
    end
  end
end
