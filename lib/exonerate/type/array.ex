defmodule Exonerate.Type.Array do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  @combining_modules Combining.modules()
  @combining_filters Combining.filters()

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  def build_filter(context, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    seen = needs_combining_seen?(context)

    filter_clauses =
      for filter <- @combining_filters, is_map_key(context, filter), reduce: [] do
        calls -> calls ++ filter_clauses(authority, pointer, opts, filter, seen)
      end

    iterator_clause =
      List.wrap(
        if Iterator.mode(context, opts) do
          iterator_clause(authority, pointer, opts, seen)
        end
      )

    if seen or opts[:tracked] do
      build_seen(call, filter_clauses, iterator_clause, opts)
    else
      build_trivial(call, filter_clauses, iterator_clause)
    end
  end

  def build_seen(call, filter_clauses, iterator_clause, opts) do
    clauses = filter_clauses ++ iterator_clause

    return =
      if opts[:tracked] do
        quote do
          {:ok, first_unseen_index}
        end
      else
        :ok
      end

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        first_unseen_index = 0

        with unquote_splicing(clauses) do
          unquote(return)
        end
      end
    end
  end

  def build_trivial(call, filter_clauses, iterator_clause) do
    clauses = filter_clauses ++ iterator_clause

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        with unquote_splicing(clauses) do
          :ok
        end
      end
    end
  end

  @seen_filters ~w(allOf anyOf if oneOf dependentSchemas $ref)

  def needs_combining_seen?(context) do
    is_map_key(context, "unevaluatedItems") and Enum.any?(@seen_filters, &is_map_key(context, &1))
  end

  defp filter_clauses(authority, pointer, opts, filter, true) when filter in @seen_filters do
    filter_call =
      Tools.call(
        authority,
        JsonPointer.join(pointer, Combining.adjust(filter)),
        Keyword.put(opts, :tracked, :array)
      )

    quote do
      [
        {:ok, new_index} <- unquote(filter_call)(array, path),
        first_unseen_index = max(first_unseen_index, new_index)
      ]
    end
  end

  defp filter_clauses(authority, pointer, opts, filter, _) do
    filter_call = Tools.call(authority, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

    [
      quote do
        :ok <- unquote(filter_call)(array, path)
      end
    ]
  end

  defp iterator_clause(authority, pointer, opts, needs_combining_seen) do
    call_opts =
      if needs_combining_seen do
        Keyword.put(opts, :tracked, :array)
      else
        opts
      end

    iterator_call = Tools.call(authority, JsonPointer.join(pointer, ":iterator"), call_opts)

    case {needs_combining_seen, opts[:tracked]} do
      {true, :array} ->
        quote do
          [
            {:ok, new_index} <- unquote(iterator_call)(array, path, first_unseen_index),
            first_unseen_index = max(new_index, first_unseen_index)
          ]
        end

      {true, _} ->
        quote do
          {:ok, _} <- unquote(iterator_call)(array, path, first_unseen_index)
        end

      {false, :array} ->
        # TODO: the second line could be optimized away!
        quote do
          [
            {:ok, new_index} <- unquote(iterator_call)(array, path),
            first_unseen_index = max(first_unseen_index, new_index)
          ]
        end

      {false, _} ->
        quote do
          :ok <- unquote(iterator_call)(array, path)
        end
    end
  end

  defmacro accessories(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_accessories(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, authority, pointer, opts) do
    opts =
      if needs_combining_seen?(context) do
        Keyword.put(opts, :tracked, :array)
      else
        opts
      end

    # TODO: break this up into two functions
    List.wrap(
      if opts[:tracked] do
        opts = Keyword.put(opts, :only, ["array"])

        for filter <- @seen_filters, is_map_key(context, filter) do
          module = @combining_modules[filter]
          pointer = JsonPointer.join(pointer, filter)

          quote do
            require unquote(module)
            unquote(module).filter(unquote(authority), unquote(pointer), unquote(opts))
          end
        end
      end
    ) ++
      List.wrap(
        if Iterator.mode(context, opts) do
          quote do
            require Exonerate.Type.Array.Iterator

            Exonerate.Type.Array.Iterator.filter(
              unquote(authority),
              unquote(pointer),
              unquote(opts)
            )

            Exonerate.Type.Array.Iterator.accessories(
              unquote(authority),
              unquote(pointer),
              unquote(opts)
            )
          end
        end
      )
  end
end
