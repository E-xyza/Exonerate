defmodule Exonerate.Filter.Properties do
  @behaviour Exonerate.Filter

  alias Exonerate.Type
  require Type

  def append_filter(object, validation) when Type.is_schema(object) do
    calls = validation.collection_calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = code(object, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :object], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path_to_call(["properties" | validation.path])
  end

  defp code(object, validation) do
    {prop_filters, prop_validators} = object
    |> Enum.map(fn {key, schema} ->
      key_path = [key, "properties" | validation.path]
      {quote do
        defp unquote(name(validation))({unquote(key), value}, _acc, path) do
          unquote(Exonerate.path_to_call(key_path))(value, Path.join(path, unquote(key)))
          true
        end
      end,
      Exonerate.Validation.from_schema(schema, key_path)}
    end)
    |> Enum.unzip

    prop_filters ++ [quote do
      defp unquote(name(validation))(_, acc, path), do: acc
    end] ++ prop_validators
  end
end
