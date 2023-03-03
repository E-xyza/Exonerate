defmodule Exonerate.Combining.OneOf do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
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
    |> Enum.with_index(&call_and_context(&1, &2, name, pointer, tracked, opts))
    |> Enum.unzip()
    |> build_code(call, schema_pointer, tracked)
    |> Tools.maybe_dump(opts)
  end

  defp call_and_context(_, index, name, pointer, tracked, opts) do
    pointer = JsonPointer.join(pointer, "#{index}")

    call =
      pointer
      |> Tools.if(tracked, &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    {quote do
       {&(unquote({call, [], Elixir}) / 2), unquote(index)}
     end,
     quote do
       require Exonerate.Context
       Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
     end}
  end

  defp build_code({calls, contexts}, call, schema_pointer, tracked) do
    quote do
      defp unquote(call)(value, path) do
        alias Exonerate.Combining
        alias Exonerate.Tools

        require Combining
        require Tools

        unquote(calls)
        |> Enum.reduce_while(
          Tools.mismatch(value, unquote(schema_pointer), path, reason: "no matches"),
          fn
            {fun, index}, {:error, opts} ->
              case fun.(value, path) do
                Combining.capture(unquote(tracked), visited) ->
                  {:cont, {Combining.capture(unquote(tracked), visited), index}}

                error ->
                  {:cont, {:error, Keyword.update(opts, :failures, [error], &[error | &1])}}
              end

            {fun, index}, {Combining.capture(unquote(tracked), visited), previous} ->
              case fun.(value, path) do
                Combining.capture(unquote(tracked), _visited) ->
                  {:halt,
                   Tools.mismatch(value, unquote(schema_pointer), path,
                     matches: [
                       Path.join(unquote(schema_pointer), "#{previous}"),
                       Path.join(unquote(schema_pointer), "#{index}")
                     ],
                     reason: "multiple matches"
                   )}

                _error ->
                  {:cont, {Combining.capture(unquote(tracked), visited), previous}}
              end
          end
        )
        |> case do
          error = {:error, _} -> error
          {ok, _} -> ok
        end
      end

      unquote(contexts)
    end
  end
end
