defmodule Exonerate.Combining.AllOf do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
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

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> Enum.with_index(&call_and_context(&1, &2, name, pointer, tracked, opts))
    |> Enum.unzip()
    |> build_code(call, tracked)
    |> Tools.maybe_dump(opts)
  end

  defp call_and_context(_, index, name, pointer, tracked, opts) do
    pointer = JsonPointer.join(pointer, "#{index}")

    call =
      pointer
      |> Tools.if(tracked, &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    {quote do
       &(unquote({call, [], Elixir}) / 2)
     end,
     quote do
       require Exonerate.Context
       Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
     end}
  end

  defp build_code({calls, contexts}, call, tracked) do
    quote do
      defp unquote(call)(value, path) do
        alias Exonerate.Combining
        require Combining
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(calls),
          Exonerate.Combining.initialize(unquote(tracked)),
          fn
            fun, Exonerate.Combining.capture(unquote(tracked), visited) ->
              case fun.(value, path) do
                Exonerate.Combining.capture(unquote(tracked), new_visited) ->
                  {:cont, Exonerate.Combining.update_set(unquote(tracked), visited, new_visited)}

                error = {:error, _} ->
                  {:halt, error}
              end
          end
        )
      end

      unquote(contexts)
    end
  end
end
