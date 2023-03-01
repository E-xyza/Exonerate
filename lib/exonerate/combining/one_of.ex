defmodule Exonerate.Combining.OneOf do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    # note this needs to change if we are doing unevaluateds, since we must
    # evaluate ALL options

    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> Enum.with_index(fn _, index ->
      pointer = JsonPointer.join(pointer, "#{index}")
      call = Tools.pointer_to_fun_name(pointer, authority: name)

      {quote do
         {&(unquote({call, [], Elixir}) / 2), unquote(index)}
       end,
       quote do
         require Exonerate.Context
         Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
       end}
    end)
    |> Enum.unzip()
    |> build_code(call, schema_pointer)
    |> Tools.maybe_dump(opts)
  end

  defp build_code({calls, contexts}, call, schema_pointer) do
    quote do
      defp unquote(call)(value, path) do
        require Exonerate.Tools

        unquote(calls)
        |> Enum.reduce_while(
          Exonerate.Tools.mismatch(value, unquote(schema_pointer), path, reason: "no matches"),
          fn
            {fun, index}, {:error, opts} ->
              case fun.(value, path) do
                :ok ->
                  {:cont, {:ok, index}}

                error ->
                  {:cont, {:error, Keyword.update(opts, :failures, [error], &[error | &1])}}
              end

            {fun, index}, {:ok, previous} ->
              case fun.(value, path) do
                :ok ->
                  {:halt,
                   Exonerate.Tools.mismatch(value, unquote(schema_pointer), path,
                     matches: [
                       Path.join(unquote(schema_pointer), "#{previous}"),
                       Path.join(unquote(schema_pointer), "#{index}")
                     ],
                     reason: "multiple matches"
                   )}

                _error ->
                  {:cont, {:ok, index}}
              end
          end
        )
        |> case do
          {:ok, _} -> :ok
          error = {:error, _} -> error
        end
      end

      unquote(contexts)
    end
  end
end
