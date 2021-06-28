defmodule Exonerate.Filter.Contains do
  @behaviour Exonerate.Filter

  def append_filter(schema, validation) do
    calls = validation.collection_calls
    |> Map.get(:array, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :array], calls)
    |> put_in([:children], children)
    |> put_in([:accumulator, :contains], 0)
    |> put_in([:post_accumulate], [name(validation) | validation.post_accumulate])
  end

  defp name(validation) do
    Exonerate.path(["contains" | validation.path])
  end

  defp code(schema, validation) do
    [quote do
      defp unquote(name(validation))({item, _index}, acc, path) do
        try do
          unquote(name(validation))(item, path)
          %{acc | contains: acc.contains + 1}
        catch
          {:error, _} -> acc
        end
      end
      defp unquote(name(validation))(%{contains: count}, list, path) do
        unless count > 0, do: Exonerate.mismatch(list, path)
      end

      unquote(Exonerate.Validation.from_schema(schema, ["contains" | validation.path]))
    end]
  end
end
