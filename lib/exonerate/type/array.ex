defmodule Exonerate.Type.Array do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  @combining_modules Combining.modules()
  @combining_filters Combining.filters()

  @seen_filters ~w(allOf anyOf if oneOf $ref)

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  #########################################################
  # trivial exceptions
  defguardp trivial_contains(context)
            when is_map_key(context, "contains") and
                   :erlang.map_get("contains", context) === false and
                   (not is_map_key(context, "minContains") or
                      :erlang.map_get("minContains", context) > 0)

  defguardp trivial_max_items(context)
            when is_map_key(context, "maxItems") and :erlang.map_get("maxItems", context) === 0

  defguardp trivial(context)
            when trivial_contains(context) or trivial_max_items(context)

  defp build_filter(context, resource, pointer, opts) when trivial_contains(context) do
    call = Tools.call(resource, pointer, opts)
    pointer = JsonPointer.join(pointer, "contains")

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(pointer), path)
      end
    end
  end

  defp build_filter(context, resource, pointer, opts) when trivial_max_items(context) do
    empty_only(context, "maxItems", resource, pointer, opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    combining_prong = List.wrap(combining(context, resource, pointer, opts))
    iterator_prong = List.wrap(iterator(context, resource, pointer, opts))

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        with unquote_splicing(combining_prong ++ iterator_prong) do
          :ok
        end
      end
    end
  end

  defp empty_only(context, reason, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    case context do
      # these three cases have no solutions because arrays will always fail
      # because one condition requires empty and the other condition requires
      # the existence of at least one.
      %{"contains" => _, "minContains" => min} when min > 0 ->
        fatal("minContains", resource, pointer, opts)

      %{"contains" => _} when not is_map_key(context, "minContains") ->
        fatal("contains", resource, pointer, opts)

      %{"minItems" => min} when min > 0 ->
        fatal("minItems", resource, pointer, opts)

      _ ->
        quote do
          defp unquote(call)([], _path), do: :ok

          defp unquote(call)(array, path) when is_list(array) do
            require Exonerate.Tools

            Exonerate.Tools.mismatch(
              array,
              unquote(resource),
              unquote(JsonPointer.join(pointer, reason)),
              path
            )
          end
        end
    end
  end

  defp fatal(reason, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        require Exonerate.Tools

        Exonerate.Tools.mismatch(
          array,
          unquote(resource),
          unquote(JsonPointer.join(pointer, reason)),
          path
        )
      end
    end
  end

  defp combining(context, resource, pointer, opts) do
    needs_unseen_index = needs_combining_seen?(context) or opts[:tracked] === :array

    Enum.flat_map(
      context,
      fn
        {filter, _} when filter in @seen_filters and needs_unseen_index ->
          combining_call =
            Tools.call(resource, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

          [
            quote do
              {:ok, next_last_unseen_index} <- unquote(combining_call)(array, path)
            end,
            quote do
              last_unseen_index = max(last_unseen_index, next_last_unseen_index)
            end
          ]

        {filter, _} when filter in @combining_filters ->
          combining_call =
            Tools.call(resource, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

          [
            quote do
              :ok <- unquote(combining_call)(array, path)
            end
          ]

        _ ->
          []
      end
    )
  end

  defp iterator(context, resource, pointer, opts) do
    if iterator_args = Iterator.args(context) do
      iterator_call = Iterator.call(resource, pointer, opts)

      uniqueness_initializer =
        List.wrap(
          if :unique_items in iterator_args do
            uniqueness_opts = Keyword.take(opts, [:use_xor_filter])

            [
              quote do
                require Exonerate.Filter.UniqueItems
              end,
              quote do
                unique_items = Exonerate.Filter.UniqueItems.initialize(unquote(uniqueness_opts))
              end
            ]
          end
        )

      uniqueness_initializer ++
        [
          quote do
            :ok <- unquote(iterator_call)(unquote_splicing(to_arg_vars(iterator_args)))
          end
        ]
    end
  end

  defp to_arg_vars(list) do
    Enum.map(list, fn
      atom when is_atom(atom) -> {atom, [], __MODULE__}
      number -> number
    end)
  end

  def needs_combining_seen?(context) do
    is_map_key(context, "unevaluatedItems") and Enum.any?(@seen_filters, &is_map_key(context, &1))
  end

  defp filter_clauses(resource, pointer, opts, filter, true) when filter in @seen_filters do
    filter_call =
      Tools.call(
        resource,
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

  defp filter_clauses(resource, pointer, opts, filter, _) do
    filter_call = Tools.call(resource, JsonPointer.join(pointer, Combining.adjust(filter)), opts)

    [
      quote do
        :ok <- unquote(filter_call)(array, path)
      end
    ]
  end

  defp iterator_clause(resource, pointer, opts, needs_combining_seen) do
    call_opts =
      if needs_combining_seen do
        Keyword.put(opts, :tracked, :array)
      else
        opts
      end

    iterator_call = Tools.call(resource, pointer, :array_iterator, call_opts)

    quote do
      unquote(iterator_call)(array, array, 0, path)
    end
  end

  defmacro accessories(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_accessories(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, _, _, _) when trivial(context), do: []

  defp build_accessories(context, resource, pointer, opts) do
    opts =
      if needs_combining_seen?(context) or opts[:tracked] do
        Keyword.merge(opts, only: ["array"], tracked: :array)
      else
        opts
      end

    build_tracked_filters(context, resource, pointer, opts) ++
      build_iterator(context, resource, pointer, opts)
  end

  defp build_tracked_filters(context, resource, pointer, opts) do
    # if we're tracked, then we need to rebuild all the filters, with the
    # tracked appendage.
    List.wrap(
      if needs_combining_seen?(context) or opts[:tracked] do
        for filter <- @seen_filters, is_map_key(context, filter) do
          module = @combining_modules[filter]
          pointer = JsonPointer.join(pointer, filter)

          quote do
            require unquote(module)
            unquote(module).filter(unquote(resource), unquote(pointer), unquote(opts))
          end
        end
      end
    )
  end

  defp build_iterator(context, resource, pointer, opts) do
    List.wrap(
      if Iterator.mode(context) do
        quote do
          require Exonerate.Type.Array.Iterator

          Exonerate.Type.Array.Iterator.filter(
            unquote(resource),
            unquote(pointer),
            unquote(opts)
          )

          Exonerate.Type.Array.Iterator.accessories(
            unquote(resource),
            unquote(pointer),
            unquote(opts)
          )
        end
      end
    )
  end
end
