defmodule :"dependentSchemas-dependencies with escaped characters" do
  def validate(value) when is_map(value) and complies_with_dependencies(value), do: :ok
  def validate(_), do: :error

  defp complies_with_dependencies(value) do
    case {Map.has_key?(value, "foo\tbar"), Map.has_key?(value, "foo'bar")} do
      {true, true} -> has_required_properties(value)
      _ -> true
    end
  end

  defp has_required_properties(value) do
    case {Map.has_key?(value, "foo\"bar"), map_size(value)} do
      {true, size} when size >= 4 -> true
      _ -> false
    end
  end
end
