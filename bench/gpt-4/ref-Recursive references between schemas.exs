defmodule :"Recursive references between schemas" do
  def validate(json) when is_map(json) do
    case Map.fetch(json, "meta") do
      {:ok, meta} when is_binary(meta) ->
        case Map.fetch(json, "nodes") do
          {:ok, nodes} when is_list(nodes) ->
            validate_nodes(nodes)

          _ ->
            {:error, "Invalid nodes"}
        end

      _ ->
        {:error, "Invalid meta"}
    end
  end

  def validate(_), do: {:error, "Invalid JSON value"}

  defp validate_nodes(nodes) do
    Enum.reduce_while(nodes, :ok, fn node, _acc ->
      case validate_node(node) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_node(node) when is_map(node) do
    case Map.fetch(node, "value") do
      {:ok, value} when is_number(value) ->
        case Map.fetch(node, "subtree") do
          {:ok, subtree} -> validate(subtree)
          :error -> :ok
          _ -> {:error, "Invalid subtree"}
        end

      _ ->
        {:error, "Invalid value"}
    end
  end

  defp validate_node(_), do: {:error, "Invalid node"}
end
