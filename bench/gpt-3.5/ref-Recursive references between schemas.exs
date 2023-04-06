defmodule :"ref-Recursive references between schemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "meta") and Map.has_key?(object, "nodes") do
      true ->
        nodes = object["nodes"]

        if is_list(nodes) do
          case Enum.all?(nodes, &validate_node/1) do
            true -> :ok
            false -> :error
          end
        else
          :error
        end

      false ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_node(node) when is_map(node) do
    subtree = node["subtree"]
    value = node["value"]

    case Map.has_key?(node, "subtree") and is_map(subtree) and Map.has_key?(subtree, "$ref") and
           Map.has_key?(node, "value") and is_number(value) do
      true -> validate(subtree)
      false -> false
    end
  end

  defp validate_node(_) do
    false
  end
end