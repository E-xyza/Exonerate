defmodule Exonerate.Filter.DependentSchemas do
  @behaviour Exonerate.Filter

  alias Exonerate.Type
  require Type

  @impl true
  def append_filter(dependency, validation) when Type.is_schema(dependency) do
    calls = validation.calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = List.insert_at(validation.children, 0, code(dependency, validation))

    validation
    |> put_in([:calls, :object], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["dependentSchemas" | validation.path])
  end

  # TODO: guard when object is the only type
  # if object is the only type, avoid the guard.
  defp code(dependencies, validation) do
    {calls, funs} = dependencies
    |> Enum.map(fn
      {key, schema} when Type.is_schema(schema) ->
        next_path = [key, "dependentSchemas" | validation.path]
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
