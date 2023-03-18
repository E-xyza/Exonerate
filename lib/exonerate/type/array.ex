defmodule Exonerate.Type.Array do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  @combining_filters Combining.filters()

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  def build_filter(context, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    track_external = opts[:tracked]
    track_internal = track_internal?(context)
    tracked = track_external || track_internal

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

    if track_internal do
      build_tracked(call, filter_clauses, iterator_clause)
    else
      build_untracked(call, filter_clauses, iterator_clause)
    end
  end

  def build_tracked(call, filter_clauses, iterator_clause) do
    clauses = filter_clauses ++ iterator_clause

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        saw_prior_to = 0

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
  @unseen_filters @combining_filters -- @seen_filters

  defp track_internal?(context) do
    is_map_key(context, "unevaluatedItems") and Enum.any?(@seen_filters, &is_map_key(context, &1))
  end

  defp filter_clauses(authority, pointer, opts, filter, true) when filter in @seen_filters do
    filter_call =
      Tools.call(
        authority,
        JsonPointer.join(pointer, Combining.adjust(filter)),
        Keyword.put(opts, :tracked, true)
      )

    quote do
      [
        {:ok, new_saw_prior_to} <- unquote(filter_call)(array, path),
        saw_prior_to = max(saw_prior_to, new_saw_prior_to)
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
    iterator_call = Tools.call(authority, JsonPointer.join(pointer, ":iterator"), Keyword.put(opts, :tracked, true))

    quote do
      :ok <- unquote(iterator_call)(array, path, saw_prior_to)
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
