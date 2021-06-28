defmodule Exonerate.Filter.Required do
  @behaviour Exonerate.Filter

  def append_filter(required, validation) when is_list(required) do
    calls = validation.calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = code(required, validation) ++ validation.children

    validation
    |> put_in([:calls, :object], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["required" | validation.path])
  end

  # if string is the only type, avoid the guard.
  defp code(required, validation) do
    {calls, funs} = required
    |> Enum.with_index
    |> Enum.map(fn {key, index} ->
      subpath = Exonerate.path([to_string(index), "required" | validation.path])
      {quote do
        unquote(subpath)(object, keys, path)
      end, quote do
        defp unquote(subpath)(object, keys, path) do
          unquote(key) in keys or Exonerate.mismatch(object, path)
        end
      end}
    end)
    |> Enum.unzip

    [quote do
      defp unquote(name(validation))(object, path) do
        keys = Map.keys(object)
        unquote_splicing(calls)
      end
    end] ++ funs
  end

end
