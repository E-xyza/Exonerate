defmodule Exonerate.Type.Object do
  @moduledoc false

  alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Combining

  @modules %{
    "minProperties" => Exonerate.Filter.MinProperties,
    "maxProperties" => Exonerate.Filter.MaxProperties,
    "required" => Exonerate.Filter.Required,
    "dependencies" => Exonerate.Filter.Dependencies,
    "dependentRequired" => Exonerate.Filter.DependentRequired,
    "dependentSchemas" => Exonerate.Filter.DependentSchemas
  }

  @outer_filters Map.keys(@modules)

  @combining_filters Combining.filters()

  defp combining_filters(opts) do
    if Draft.before?(Keyword.get(opts, :draft, "2020-12"), "2019-09") do
      @combining_filters -- ["$ref"]
    else
      @combining_filters
    end
  end

  def remove_degenerate_features(
        subschema = %{"additionalProperties" => _, "unevaluatedProperties" => _}
      ) do
    # additionalProperties clobbers unevaluatedProperties
    Map.delete(subschema, "unevaluatedProperties")
  end

  def remove_degenerate_features(subschema = %{"additionalProperties" => true}) do
    # additionalProperties clobbers unevaluatedProperties
    Map.delete(subschema, "additionalProperties")
  end

  def remove_degenerate_features(subschema = %{"unevaluatedProperties" => true}) do
    # additionalProperties clobbers unevaluatedProperties
    Map.delete(subschema, "unevaluatedProperties")
  end

  def remove_degenerate_features(subschema), do: subschema

  def filter(subschema, name, pointer, opts) do
    tracked = Keyword.get(opts, :track_properties, false)
    subschema = remove_degenerate_features(subschema)
    opts = add_internal_tracker(subschema, opts)

    combining_filters =
      make_combining_filters(combining_filters(opts), subschema, name, pointer, opts)

    outer_filters = make_filters(@outer_filters, subschema, name, pointer)

    iterator_filter = iterator_filter(subschema, name, pointer, opts)

    call =
      pointer
      |> Tools.if(tracked, &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    seen_prefix =
      case opts[:internal_tracking] do
        type when type === :unevaluated or tracked ->
          quote do
            seen = MapSet.new()
          end

        _ ->
          []
      end

    result =
      if tracked do
        quote do
          {:ok, seen}
        end
      else
        :ok
      end

    quote do
      defp unquote(call)(content, path) when is_map(content) do
        unquote(seen_prefix)

        with unquote_splicing(combining_filters ++ outer_filters ++ iterator_filter) do
          unquote(result)
        end
      end
    end
  end

  defp make_combining_filters(filters, subschema, name, pointer, opts) do
    if opts[:track_properties] || Map.has_key?(subschema, "unevaluatedProperties") do
      for filter <- filters, is_map_key(subschema, filter), reduce: [] do
        acc ->
          call =
            pointer
            |> JsonPointer.join(Combining.adjust(filter) ++ [":tracked"])
            |> Tools.pointer_to_fun_name(authority: name)

          quote do
            [{:ok, new_seen} <- unquote(call)(content, path), seen = MapSet.union(seen, new_seen)]
          end ++ acc
      end
    else
      make_filters(filters, subschema, name, pointer)
    end
  end

  defp make_filters(filters, subschema, name, pointer) do
    for filter <- filters, is_map_key(subschema, filter) do
      call =
        pointer
        |> JsonPointer.join(Combining.adjust(filter))
        |> Tools.pointer_to_fun_name(authority: name)

      quote do
        :ok <- unquote(call)(content, path)
      end
    end
  end

  defp iterator_filter(_subschema, name, pointer, opts) do
    call =
      pointer
      |> JsonPointer.join(":iterator")
      |> Tools.if(opts[:track_properties], &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    filter_result =
      if opts[:track_properties] do
        quote do
          {:ok, seen}
        end
      else
        :ok
      end

    List.wrap(
      case opts[:internal_tracking] do
        :unevaluated ->
          quote do
            unquote(filter_result) <- unquote(call)(content, path, seen)
          end

        _ ->
          quote do
            unquote(filter_result) <- unquote(call)(content, path)
          end
      end
    )
  end

  @internal_tracker_keys Combining.filters() -- ["not"]

  defp add_internal_tracker(subschema, opts) do
    mode =
      cond do
        opts[:track_properties] ->
          :unevaluated

        is_map_key(subschema, "propertyNames") ->
          nil

        is_map_key(subschema, "additionalProperties") ->
          :additional

        is_map_key(subschema, "unevaluatedProperties") ->
          if Enum.any?(@internal_tracker_keys, &is_map_key(subschema, &1)) do
            :unevaluated
          else
            :additional
          end

        true ->
          nil
      end

    Keyword.put(opts, :internal_tracking, mode)
  end

  def accessories(subschema, name, pointer, opts) do
    opts_with_tracker = add_internal_tracker(subschema, opts)

    List.wrap(
      quote do
        require Exonerate.Type.Object.Iterator

        Exonerate.Type.Object.Iterator.from_cached(
          unquote(name),
          unquote(pointer),
          unquote(opts_with_tracker)
        )
      end
    ) ++
      for filter_name <- @outer_filters,
          is_map_key(subschema, filter_name) do
        module = @modules[filter_name]
        pointer = JsonPointer.join(pointer, filter_name)

        quote do
          require unquote(module)
          unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
        end
      end
  end
end
