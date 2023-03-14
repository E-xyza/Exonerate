defmodule Exonerate.Type.Array.Find do
  @moduledoc false

  # macros for "find-mode" array filtering.  This is for cases when accepting
  # the array occurs when a single item passes with :ok, this is distinct from
  # when the rejecting the array occurs when a single item fails with error.
  #
  # modes are selected using Exonerate.Type.Array.Filter.Iterator.mode/1

  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro iterator(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_iterator(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # at its core, the iterator is a reduce-while that encapsulates a with
  # statement.  The reduce-while operates over the entire array, and halts when
  # :ok is encountered.

  # note that there are only three cases for this mode to be activated, and
  # we're going to write out each of these cases by hand.

  defp build_iterator(
         context = %{"contains" => _, "minItems" => length},
         authority,
         pointer,
         opts
       ) do
    call = Iterator.call(authority, pointer, opts)
    contains_pointer = JsonPointer.join(pointer, "contains")
    contains_call = Tools.call(authority, contains_pointer, opts)
    needed = Map.get(context, "minContains", 1)

    quote do
      defp unquote(call)(content, path) do
        require Exonerate.Tools

        content
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(content, unquote(contains_pointer), path), 0, 0},
          fn
            _item, {:ok, index, count} when index >= unquote(length) ->
              {:halt, {:ok, index, count}}

            item, {{:error, error_so_far}, index, count} ->
              case unquote(contains_call)(item, Path.join(path, "#{index}")) do
                :ok when count >= unquote(needed) ->
                  {:cont, {:ok, index + 1, count}}

                :ok ->
                  {:cont, {:error, error_so_far}, index + 1, count + 1}

                Exonerate.Tools.error_match(error) ->
                  new_params = Keyword.update(error_so_far, :failures, [error], &[error | &1])
                  {:cont, {{:error, error_so_far}, index + 1}}
              end
          end
        )
        |> case do
          {:ok, index, _count} when index < unquote(length) - 1 ->
            Exonerate.Tools.mismatch(
              content,
              unquote(JsonPointer.join(pointer, "minItems")),
              path
            )

          {:ok, _index, count} when count < unquote(needed) ->
            Exonerate.Tools.mismatch(
              content,
              unquote(JsonPointer.join(pointer, "minContains")),
              path
            )

          {Exonerate.Tools.error_match(error), _} ->
            error
        end
      end
    end
  end

  # contains-only case
  defp build_iterator(schema = %{"contains" => _}, authority, pointer, opts) do
    call = Iterator.call(authority, pointer, opts)
    contains_pointer = JsonPointer.join(pointer, "contains")
    contains_call = Tools.call(authority, contains_pointer, opts)
    needed = Map.get(schema, "minContains", 1)

    quote do
      defp unquote(call)(content, path) do
        require Exonerate.Tools

        content
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(content, unquote(contains_pointer), path), 0, 0},
          fn
            item, {{:error, params}, index, count} ->
              case unquote(contains_call)(item, path) do
                :ok when count < unquote(needed - 1) ->
                  {:cont, {{:error, params}, index, count + 1}}

                :ok ->
                  {:halt, {:ok}}

                Exonerate.Tools.error_match(error) ->
                  new_params = Keyword.update(params, :failures, [error], &[error | &1])
                  {:cont, {{:error, params}, index + 1, count}}
              end
          end
        )
        |> elem(0)
      end
    end
  end

  # minItems-only case

  defp build_iterator(%{"minItems" => length}, authority, pointer, opts) do
    call = Iterator.call(authority, pointer, opts)

    quote do
      defp unquote(call)(content, path) do
        require Exonerate.Tools

        content
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(
             content,
             unquote(JsonPointer.join(pointer, "minItems")),
             path
           ), 0},
          fn
            _item, {error, index} when index < unquote(length - 1) ->
              {:cont, {error, index + 1}}

            _item, {error, index} ->
              {:halt, {:ok}}
          end
        )
        |> elem(0)
      end
    end
  end
end
