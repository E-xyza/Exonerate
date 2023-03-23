defmodule Exonerate.Combining.AnyOf do
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

  # special case, only one item
  defp build_filter({[any_of_call], [context]}, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(value, path) do
        unquote(any_of_call)(value, path)
      end

      unquote(context)
    end
  end

  defp build_filter({calls, contexts}, authority, pointer, opts) do
    function =
      case opts[:tracked] do
        :object ->
          build_tracked_object(calls, authority, pointer, opts)

        :array ->
          build_tracked_array(calls, authority, pointer, opts)

        nil ->
          build_untracked(calls, authority, pointer, opts)
      end

    quote do
      unquote(function)
      unquote(contexts)
    end
  end

  defp build_tracked_object(calls, authority, pointer, opts) do
    # NB we need to complete reducing over the lambdas because when tracked, we must
    # honor all branches which have found content.

    lambdas = Enum.map(calls, &to_lambda/1)
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        Enum.reduce(
          unquote(lambdas),
          Exonerate.Tools.mismatch(value, unquote(pointer), path),
          fn
            fun, {:error, opts} ->
              case fun.(value, path) do
                ok = {:ok, _seen} ->
                  ok

                Exonerate.Tools.error_match(error) ->
                  {:error, Keyword.update(opts, :failures, [error], &[error | &1])}
              end

            fun, {:ok, seen} ->
              case fun.(value, path) do
                ok = {:ok, new_seen} ->
                  {:ok, MapSet.union(seen, new_seen)}

                Exonerate.Tools.error_match(_error) ->
                  {:ok, seen}
              end
          end
        )
      end
    end
  end

  defp build_tracked_array(calls, authority, pointer, opts) do
    # NB we need to complete reducing over the lambdas because when tracked, we must
    # honor all branches which have found content.

    lambdas = Enum.map(calls, &to_lambda/1)
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        Enum.reduce(
          unquote(lambdas),
          Exonerate.Tools.mismatch(value, unquote(pointer), path),
          fn
            fun, {:error, opts} ->
              case fun.(value, path) do
                ok = {:ok, _seen} ->
                  ok

                Exonerate.Tools.error_match(error) ->
                  {:error, Keyword.update(opts, :failures, [error], &[error | &1])}
              end

            fun, {:ok, first_unseen_index} ->
              case fun.(value, path) do
                ok = {:ok, new_index} ->
                  {:ok, max(first_unseen_index, new_index)}

                Exonerate.Tools.error_match(_error) ->
                  {:ok, first_unseen_index}
              end
          end
        )
      end
    end
  end

  defp build_untracked(calls, authority, pointer, opts) do
    lambdas = Enum.map(calls, &to_lambda/1)
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        Enum.reduce_while(
          unquote(lambdas),
          Exonerate.Tools.mismatch(value, unquote(pointer), path),
          fn
            fun, {:error, opts} ->
              case fun.(value, path) do
                :ok ->
                  {:halt, :ok}

                Exonerate.Tools.error_match(error) ->
                  {:cont, {:error, Keyword.update(opts, :failures, [error], &[error | &1])}}
              end
          end
        )
      end
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
