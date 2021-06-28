defmodule Exonerate.Filter.Dependencies do
  @behaviour Exonerate.Filter

  def append_filter(dependency, validation) when is_map(dependency) do
    calls = validation.calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = List.insert_at(validation.children, 0, code(dependency, validation))

    validation
    |> put_in([:calls, :object], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["dependencies" | validation.path])
  end

  # TODO: guard when object is the only type
  # if object is the only type, avoid the guard.
  defp code(dependencies, validation) do
    {calls, funs} = dependencies
    |> Enum.map(fn
      {key, otherkeys} when is_list(otherkeys) ->
        {quote do
          defp unquote(name(validation))(object = %{unquote(key) => _}, path) do
            unquote(otherkeys)
            |> Enum.with_index
            |> Enum.each(fn {otherkey, index} ->
              unless is_map_key(object, otherkey) do
                Exonerate.mismatch(object, path, guard: Path.join(unquote(key), to_string(index)))
              end
            end)
          end
        end, :ok}
      {key, schema} when is_map(schema) ->
        next_path = [key, "dependencies" | validation.path]
        {quote do
          defp unquote(name(validation))(object = %{unquote(key) => _}, path) do
            unquote(Exonerate.path(next_path))(object, path)
          end
        end,
        Exonerate.Validation.from_schema(schema, next_path)
        }
      end)
    |> Enum.unzip

    calls ++ [quote do
      defp unquote(name(validation))(_, _), do: :ok
    end] ++ funs
  end
end
