defmodule Exonerate.Combining.AllOf do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> Enum.with_index(&call_and_context(&1, &2, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter({[all_of_call], [context]}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(data, path) do
        unquote(all_of_call)(data, path)
      end

      unquote(context)
    end
  end

  defp build_filter({calls, contexts}, resource, pointer, opts) do
    lambdas = Enum.map(calls, &to_lambda/1)
    call = Tools.call(resource, pointer, opts)

    case opts[:tracked] do
      :object ->
        build_tracked_object(call, lambdas, contexts)

      :array ->
        build_tracked_array(call, lambdas, contexts)

      nil ->
        build_untracked(call, lambdas, contexts)
    end
  end

  defp build_tracked_object(call, lambdas, contexts) do
    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(lambdas),
          {:ok, MapSet.new()},
          fn
            fun, {:ok, seen} ->
              case fun.(data, path) do
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

  defp build_tracked_array(call, lambdas, contexts) do
    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(lambdas),
          {:ok, 0},
          fn
            fun, {:ok, first_unseen_index} ->
              case fun.(data, path) do
                {:ok, new_index} ->
                  {:cont, {:ok, max(first_unseen_index, new_index)}}

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
      defp unquote(call)(data, path) do
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(lambdas),
          :ok,
          fn
            fun, :ok ->
              case fun.(data, path) do
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

  defp call_and_context(_, index, resource, pointer, opts) do
    pointer = JsonPointer.join(pointer, "#{index}")
    call = Tools.call(resource, pointer, opts)

    context =
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end

    {call, context}
  end
end
