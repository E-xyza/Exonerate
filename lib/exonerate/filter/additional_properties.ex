defmodule Exonerate.Filter.AdditionalProperties do
  @behaviour Exonerate.Filter

  def append_filter(schema, validation) do
    calls = validation.collection_calls
    |> Map.get(:object, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation) ++ validation.children

    validation
    |> put_in([:collection_calls, :object], calls)
    |> put_in([:children], children)
  end

  defp name(validation) do
    Exonerate.path(["additionalProperties" | validation.path])
  end

  defp code(schema, validation) do
    [quote do
      defp unquote(name(validation))({key, object}, acc, path) do
        unless acc do
          try do
            unquote(name(validation))(object, path)
          catch
            err = {:error, opts} ->
              err_val = opts[:error_value]
              throw {:error, Keyword.put(opts, :error_value, %{key => err_val})}
          end
        end
      end
      unquote(Exonerate.Validation.from_schema(schema, ["additionalProperties" | validation.path]))
    end]
  end

end
