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
    |> put_in([:accumulator, :contains], false)
  end

  defp name(validation) do
    Exonerate.path(["contains" | validation.path])
  end

  defp code(schema, validation) do
    [quote do
      defp unquote(name(validation))({item, _index}, acc, path) do
        try do
          unquote(name(validation))(item, path)
          %{acc | contains: true}
        catch
          {:error, _} -> acc
        end
      end
      unquote(Exonerate.Validation.from_schema(schema, ["contains" | validation.path]))
    end]
  end

  defmacro postprocess(nil, _, _, _), do: :ok
  defmacro postprocess(_, acc, list, path) do
    quote do
      unless unquote(acc).contains, do: Exonerate.mismatch(unquote(list), unquote(path), guard: "contains")
    end
  end
end
