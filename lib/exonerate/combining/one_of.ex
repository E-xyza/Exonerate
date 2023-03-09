defmodule Exonerate.Combining.OneOf do
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

    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        unquote(lambdas)
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(value, unquote(pointer), path), 0},
          fn
            fun, {{:error, opts}, index} ->
              case fun.(value, path) do
                :ok ->
                  {:cont, {:ok, index, index + 1}}

                error ->
                  {:cont,
                   {{:error, Keyword.update(opts, :failures, [error], &[error | &1])}, index + 1}}
              end

            fun, {:ok, last, index} ->
              case fun.(value, path) do
                :ok ->
                  matches =
                    Enum.map([last, index], fn slot ->
                      "/" <> Path.join(unquote(pointer) ++ ["#{slot}"])
                    end)

                  {:halt,
                   {Exonerate.Tools.mismatch(value, unquote(pointer), path,
                      matches: matches,
                      reason: "multiple matches"
                    )}}

                error ->
                  {:cont, {:ok, last, index}}
              end
          end
        )
        |> elem(0)
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
