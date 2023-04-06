defmodule :"unevaluatedItems-unevaluatedItems with items-gpt-3.5" do
  def validate(object) when is_list(object) do
    validate_items(object) and validate_prefix_items(object)
  end

  def validate(object) do
    :error
  end

  defp validate_items(_) do
    :ok
  end

  defp validate_items([], _) do
    :ok
  end

  defp validate_items([first | rest], schema) do
    case validate_schema(first, schema[:items]) do
      :ok -> validate_items(rest, schema)
      _ -> :error
    end
  end

  defp validate_prefix_items([], _) do
    :ok
  end

  defp validate_prefix_items(list, schema) do
    case Enum.reduce(schema[:prefixItems], {[], list}, &validate_with_prefix_schema/2) do
      {prefix, remaining} ->
        validate_items(
          remaining,
          schema
          |> Map.put(
            :items,
            schema[:unevaluatedItems]
          )
        )

      _ ->
        :error
    end
  end

  defp validate_with_prefix_schema({schema, list}, _accumulator) do
    case validate_schema(Enum.take(list, Enum.count(schema)), schema) do
      :ok -> {schema, Enum.drop(list, Enum.count(schema))}
      _ -> {:error, nil}
    end
  end

  defp validate_schema(value, schema) do
    case schema do
      %{type: "array"} ->
        if is_list(value) do
          validate_items(value, schema)
        else
          :error
        end

      %{type: "string"} ->
        if is_binary(value) do
          :ok
        else
          :error
        end

      _ ->
        :ok
    end
  end
end