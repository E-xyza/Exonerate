defmodule Exonerate.Type.Array do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  @combining_modules Combining.modules()
  @combining_filters Combining.filters()

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  #########################################################
  # trivial exception

  def build_filter(%{"contains" => false}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    pointer = JsonPointer.join(pointer, "contains")

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(array, unquote(resource), unquote(pointer), path)
      end
    end
  end

  def build_filter(context, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    iterator_call = Iterator.call(resource, pointer, opts)

    if iterator_args = Iterator.args(context) do
      uniqueness_initializer =
        if :unique in iterator_args do
          uniqueness_opts = Keyword.take(opts, [:use_xor_filter])

          quote do
            require Exonerate.Filter.UniqueItems
            unique = Exonerate.Filter.UniqueItems.initialize(unquote(uniqueness_opts))
          end
        end

      quote do
        defp unquote(call)(array, path) when is_list(array) do
          unquote(uniqueness_initializer)
          unquote(iterator_call)(unquote_splicing(to_arg_vars(iterator_args)))
        end
      end
    else
      quote do
        defp unquote(call)(array, _path) when is_list(array) do
          :ok
        end
      end
    end
  end

  defp to_arg_vars(list) do
    Enum.map(list, fn
      atom when is_atom(atom) -> {atom, [], __MODULE__}
      number -> number
    end)
  end

  @seen_filters ~w(allOf anyOf if oneOf dependentSchemas $ref)

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
