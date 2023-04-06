defmodule :"unevaluatedItems-unevaluatedItems with not-gpt-3.5" do
  def validate(data) when is_list(data) do
    case validate_items(data) do
      :ok -> :ok
      error -> error
    end
  end

  def validate(data) do
    :error
  end

  defp validate_items([], _) do
    :ok
  end

  defp validate_items([item | rest], schema) do
    case validate_item(item, schema) do
      :ok -> validate_items(rest, schema)
      error -> error
    end
  end

  defp validate_item(item, schema) when is_map(schema) do
    case Map.fetch(schema, "not") do
      {:ok, not_schema} ->
        if validate_item(item, not_schema) == :ok do
          :error
        else
          :ok
        end

      :error ->
        case Map.fetch(schema, "prefixItems") do
          {:ok, prefix_items} ->
            case Enum.member?(prefix_items, item) do
              true -> :ok
              false -> :error
            end

          :error ->
            case Map.fetch(schema, "const") do
              {:ok, const} ->
                if const == item do
                  :ok
                else
                  :error
                end

              :error ->
                case Map.fetch(schema, "type") do
                  {:ok, "array"} ->
                    case Map.fetch(schema, "unevaluatedItems") do
                      {:ok, false} ->
                        %{}
                        |> validate_item(item, %{prefixItems: prefix_items})
                        |> validate_item(item, %{const: const})
                        |> validate_item(item, %{type: "boolean"})
                        |> validate_item(item, %{type: "number"})
                        |> validate_item(item, %{type: "integer"})
                        |> validate_item(item, %{type: "string"})
                        |> validate_item(item, %{type: "object"})

                      {:ok, true} ->
                        validate_item(item, schema)

                      :error ->
                        :ok
                    end

                  {:ok, "boolean"} ->
                    if is_boolean(item) do
                      :ok
                    else
                      :error
                    end

                  {:ok, "number"} ->
                    if is_number(item) do
                      :ok
                    else
                      :error
                    end

                  {:ok, "integer"} ->
                    if is_integer(item) do
                      :ok
                    else
                      :error
                    end

                  {:ok, "string"} ->
                    if is_binary(item) do
                      :ok
                    else
                      :error
                    end

                  {:ok, "object"} ->
                    if is_map(item) do
                      :ok
                    else
                      :error
                    end

                  :error ->
                    :error
                end
            end
        end
    end
  end

  defp validate_item(_, _) do
    :error
  end
end