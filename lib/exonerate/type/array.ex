defmodule Exonerate.Type.Array do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  @combining_modules Combining.modules()
  @combining_filters Combining.filters()

  defmacro filter(authority, pointer, opts) do
    if opts[:tracked] do
      quote do
        require Exonerate.Type.Array.Tracked
        Exonerate.Type.Array.Tracked.filter(unquote(authority), unquote(pointer), unquote(opts))
      end
    else
      __CALLER__
      |> Tools.subschema(authority, pointer)
      |> build_filter(authority, pointer, opts)
      |> Tools.maybe_dump(opts)
    end
  end

  def build_filter(context, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    tracked = track_internal?(context) or opts[:tracked]

    filter_clauses =
      for filter <- @combining_filters, is_map_key(context, filter), reduce: [] do
        calls -> calls ++ filter_clauses(authority, pointer, opts, filter, tracked)
      end

    iterator_clause =
      List.wrap(
        if Iterator.mode(context) do
          iterator_clause(authority, pointer, opts, tracked)
        end
      )

    if tracked do
      build_tracked(call, filter_clauses, iterator_clause)
    else
      build_untracked(call, filter_clauses, iterator_clause)
    end
  end

  def build_tracked(call, filter_clauses, iterator_clause) do
    clauses = filter_clauses ++ iterator_clause

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        first_unseen_index = 0

        with unquote_splicing(clauses) do
          :ok
        end
      end
    end
  end

  def build_untracked(call, filter_clauses, iterator_clause) do
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

  def track_internal?(context) do
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
        {:ok, new_first_unseen_index} <- unquote(filter_call)(array, path),
        first_unseen_index = max(first_unseen_index, new_first_unseen_index)
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

  defp iterator_clause(authority, pointer, opts, true) do
    iterator_call =
      Tools.call(
        authority,
        JsonPointer.join(pointer, ":iterator"),
        Keyword.put(opts, :tracked, :array)
      )

    quote do
      :ok <- unquote(iterator_call)(array, path, first_unseen_index)
    end
  end

  defp iterator_clause(authority, pointer, opts, _) do
    iterator_call = Tools.call(authority, JsonPointer.join(pointer, ":iterator"), opts)

    quote do
      :ok <- unquote(iterator_call)(array, path)
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
      if track_internal?(context) do
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
        if Iterator.mode(context) do
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
