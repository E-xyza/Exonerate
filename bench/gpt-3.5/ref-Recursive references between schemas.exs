defmodule :"Recursive references between schemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "meta") and Map.has_key?(object, "nodes") do
      true ->
        case Enum.all?(object["nodes"], fn node -> validate_node(node) == :ok end) do
          true -> :ok
          false -> :error
        end

      false ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_node(node) do
    case Map.has_key?(node, "value") do
      true ->
        case Map.has_key?(node, "subtree") do
          true -> validate(node["subtree"])
          false -> :ok
        end

      false ->
        :error
    end
  end
end