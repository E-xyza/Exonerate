defmodule Exonerate.Filter.DependentRequired do
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
    Exonerate.path(["dependentRequired" | validation.path])
  end

  defp code(dependencies, validation) do
    calls = Enum.map(dependencies,
      fn {key, otherkeys} when is_list(otherkeys) ->
        quote do
          defp unquote(name(validation))(object = %{unquote(key) => _}, path) do
            unquote(otherkeys)
            |> Enum.with_index
            |> Enum.each(fn {otherkey, index} ->
              unless is_map_key(object, otherkey) do
                Exonerate.mismatch(object, path, guard: Path.join(unquote(key), to_string(index)))
              end
            end)
          end
        end
      end)

    calls ++ [quote do
      defp unquote(name(validation))(_, _), do: :ok
    end]
  end
end
