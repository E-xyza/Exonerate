defmodule Exonerate.Combining.AnyOf do
  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    # note this needs to change if we are doing unevaluateds, since we must
    # evaluate ALL options
    opts =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
      |> case do
        %{"unevaluatedProperties" => _} -> Keyword.put(opts, :track_properties, true)
        _ -> opts
      end

    tracked = opts[:track_properties]

    call =
      pointer
      |> Tools.if(tracked, &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    schema_pointer = JsonPointer.to_uri(pointer)

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> Enum.with_index(&call_and_context(&1, &2, name, pointer, opts))
    |> Enum.unzip()
    |> build_filter(call, schema_pointer, tracked)
    |> Tools.maybe_dump(opts)
  end

  defp call_and_context(_, index, name, pointer, opts) do
    pointer = JsonPointer.join(pointer, "#{index}")

    call =
      pointer
      |> Tools.if(opts[:track_properties], &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    {quote do
       &(unquote({call, [], Elixir}) / 2)
     end,
     quote do
       require Exonerate.Context
       Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
     end}
  end

  defp build_filter({calls, contexts}, call, schema_pointer, true) do
    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        Enum.reduce(
          unquote(calls),
          Exonerate.Tools.mismatch(value, unquote(schema_pointer), path, failures: []),
          fn
            fun, {:error, msg} ->
              case fun.(value, path) do
                {:ok, visited} ->
                  {:ok, visited}

                {:error, error} ->
                  {:error, Keyword.update(msg, :failures, [error], &[error | &1])}
              end

            fun, {:ok, visited} ->
              case fun.(value, path) do
                {:ok, new_visited} -> {:ok, MapSet.union(visited, new_visited)}
                {:error, error} -> {:ok, visited}
              end
          end
        )
      end

      unquote(contexts)
    end
  end

  defp build_filter({calls, contexts}, call, schema_pointer, _) do
    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(calls),
          Exonerate.Tools.mismatch(value, unquote(schema_pointer), path),
          fn
            fun, {:error, opts} ->
              case fun.(value, path) do
                :ok ->
                  {:halt, :ok}

                error ->
                  {:cont, {:error, Keyword.update(opts, :failures, [error], &[error | &1])}}
              end
          end
        )
      end

      unquote(contexts)
    end
  end
end
