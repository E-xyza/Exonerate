defmodule Exonerate.Filter.PropertyNames do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(schema, validation) do
    calls = validation.collection_calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = [
        code(schema, validation),
        Exonerate.Validation.from_schema(schema, ["propertyNames" | validation.path])
      ] ++ validation.children

    validation
    |> put_in([:collection_calls, :object], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["propertyNames" | validation.path])
  end

  defp code(_schema, validation) do
    quote do
      defp unquote(name(validation))({key, _value}, _acc, path) do
        unquote(name(validation))(key, Path.join(path, key))
      end
    end
  end
end
