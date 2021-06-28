defmodule Exonerate.Filter.Items do
  @behaviour Exonerate.Filter

  # enumerated, tuple validation
  def append_filter(schema, validation) when is_list(schema) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation, :list) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
    |> put_in([:accumulator, :tuple_size], length(schema))
  end
  # generic validation
  def append_filter(schema, validation) when is_map(schema) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation, :map) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["items" | validation.path])
  end
  defp name(validation, index) do
    Exonerate.path([to_string(index), "items" | validation.path])
  end

  defp code(schema, validation, :list) do
    {calls, funs} = schema
    |> Enum.with_index
    |> Enum.map(fn {item_schema, index} ->
      {
        quote do
          defp unquote(name(validation))({item, unquote(index)}, acc, path) do
            unquote(name(validation, index))(item, Path.join(path, to_string(unquote(index))))
            acc
          end
        end,
        Exonerate.Validation.from_schema(item_schema, [to_string(index), "items" | validation.path])
      }
    end)
    |> Enum.unzip

    calls ++ [quote do
      defp unquote(name(validation))({item, _}, acc, path), do: acc
    end] ++ funs
  end

  defp code(schema, validation, :map) do
    [quote do
       defp unquote(name(validation))({item, index}, acc, path) do
         unquote(name(validation))(item, Path.join(path, to_string(index)))
         acc
       end
     end,
     Exonerate.Validation.from_schema(schema, ["items" | validation.path])]
  end
end
