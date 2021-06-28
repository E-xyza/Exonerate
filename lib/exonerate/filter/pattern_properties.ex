defmodule Exonerate.Filter.PatternProperties do
  @behaviour Exonerate.Filter

  alias Exonerate.Type
  require Type

  def append_filter(object, validation) when Type.is_schema(object) do
    collection_calls = validation.collection_calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = code(object, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :object], collection_calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["patternProperties" | validation.path])
  end

  defp code(object, validation) do
    {calls, funs} = object
    |> Enum.map(fn
      {pattern, schema} ->
        subpath = [pattern, "patternProperties" | validation.path]

        {quote do
           acc = unquote(Exonerate.path(subpath))(key, value, acc, Path.join(path, key))
         end,
         quote do
           defp unquote(Exonerate.path(subpath))(key, value, acc, path) do
             if Regex.match?(sigil_r(<<unquote(pattern)>>, []), key) do
               unquote(Exonerate.path(subpath))(value, path)
               true
             else
               acc
             end
           end
           unquote(Exonerate.Validation.from_schema(schema, subpath))
         end}
    end)
    |> Enum.unzip

    [quote do
      defp unquote(name(validation))({key, value}, acc, path) do
        unquote_splicing(calls)
        acc
      end
    end] ++ funs
  end

end
