defmodule Exonerate.Combining.AllOf do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> Enum.with_index(&call_and_context(&1, &2, authority, pointer, opts))
    |> Enum.unzip()
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter({[all_of_call], [context]}, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(value, path) do
        unquote(all_of_call)(value, path)
      end

      unquote(context)
    end
  end

  defp build_filter({calls, contexts}, authority, pointer, opts) do
    lambdas = Enum.map(calls, &to_lambda/1)
    call = Tools.call(authority, pointer, opts)

    if opts[:tracked] do
      build_tracked(call, lambdas, contexts)
    else
      build_untracked(call, lambdas, contexts)
    end
  end

  defp build_tracked(call, lambdas, contexts) do
    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(lambdas),
          {:ok, MapSet.new()},
          fn
            fun, {:ok, seen} ->
              case fun.(value, path) do
                {:ok, new_seen} ->
                  {:cont, {:ok, MapSet.union(seen, new_seen)}}

                Exonerate.Tools.error_match(error) ->
                  {:halt, error}
              end
          end
        )
      end

      unquote(contexts)
    end
  end

  defp build_untracked(call, lambdas, contexts) do
    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(lambdas),
          :ok,
          fn
            fun, :ok ->
              case fun.(value, path) do
                :ok ->
                  {:cont, :ok}

                Exonerate.Tools.error_match(error) ->
                  {:halt, error}
              end
          end
        )
      end

      unquote(contexts)
    end
  end

  defp to_lambda(call) do
    quote do
      &(unquote({call, [], Elixir}) / 2)
    end
  end

  defp call_and_context(_, index, authority, pointer, opts) do
    pointer = JsonPointer.join(pointer, "#{index}")
    call = Tools.call(authority, pointer, opts)

    context =
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
      end

    {call, context}
  end
end
