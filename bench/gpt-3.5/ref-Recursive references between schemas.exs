defmodule :"ref-Recursive references between schemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{"meta" => _meta, "nodes" => nodes}) do
    validate_nodes(nodes)
  end

  defp validate_object(_) do
    :error
  end

  defp validate_nodes([]) do
    :ok
  end

  defp validate_nodes([node | nodes]) do
    case validate_node(node) do
      :ok -> validate_nodes(nodes)
      _ -> :error
    end
  end

  defp validate_node(%{"value" => _value, "subtree" => subtree}) do
    validate_object(subtree)
  end

  defp validate_node(_) do
    :error
  end
end
