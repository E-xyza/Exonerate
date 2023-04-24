defmodule Exonerate.Type.Object.Iterator do
  @moduledoc false

  alias Exonerate.Tools
  alias Exonerate.Type.Object

  # Note that we don't need

  @iterator_modules %{
    "properties" => Exonerate.Filter.Properties,
    "propertyNames" => Exonerate.Filter.PropertyNames,
    "patternProperties" => Exonerate.Filter.PatternProperties
  }

  @iterators Map.keys(@iterator_modules)

  @visited ["properties", "patternProperties"]

  @finalizer_modules %{
    "additionalProperties" => Exonerate.Filter.AdditionalProperties,
    "unevaluatedProperties" => Exonerate.Filter.UnevaluatedProperties
  }

  @finalizers Map.keys(@finalizer_modules)

  @filters @iterators ++ @finalizers
  @modules Map.merge(@iterator_modules, @finalizer_modules)

  def needed?(context) do
    Enum.any?(@filters, &is_map_key(context, &1))
  end

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  # RENAME TRACKED TO SEEN

  defp build_filter(context, resource, pointer, opts) do
    call = Tools.call(resource, pointer, :object_iterator, opts)
    visitor_call = visitor_call(context, resource, pointer, opts)

    tracked = needs_tracked?(opts, context)

    filters =
      for filter <- @iterators, is_map_key(context, filter), reduce: [] do
        acc ->
          opts = adjust_opts(opts, filter, context)

          filter_call = Tools.call(resource, JsonPointer.join(pointer, filter), opts)

          if filter in @visited and (tracked or visitor_call) do
            acc ++
              quote do
                [
                  {:ok, new_visited} <- unquote(filter_call)({key, value}, path),
                  visited = visited or new_visited
                ]
              end
          else
            acc ++
              quote do
                [:ok <- unquote(filter_call)({key, value}, path)]
              end
          end
      end

    cond do
      Object.needs_seen?(context) ->
        build_seen(call, visitor_call, filters, opts[:tracked])

      visitor_call ->
        build_visited(call, visitor_call, filters, opts[:tracked])

      tracked ->
        build_tracked(call, filters)

      true ->
        build_trivial(call, filters)
    end
  end

  defp visitor_call(context, resource, pointer, opts) do
    case context do
      %{"additionalProperties" => _} ->
        Tools.call(resource, JsonPointer.join(pointer, "additionalProperties"), opts)

      %{"unevaluatedProperties" => _} ->
        Tools.call(resource, JsonPointer.join(pointer, "unevaluatedProperties"), opts)

      _ ->
        nil
    end
  end

  # TODO: merge these guys.

  defp build_seen(call, visitor_call, filters, true) do
    filters =
      filters ++
        quote do
          [
            false <- key in seen or visited,
            :ok <- unquote(visitor_call)(value, Path.join(path, key))
          ]
        end

    quote do
      defp unquote(call)(object, path, seen) do
        require Exonerate.Tools

        Enum.reduce_while(object, {:ok, seen}, fn
          {key, value}, {:ok, seen} ->
            visited = false

            with unquote_splicing(filters) do
              {:cont, {:ok, MapSet.put(seen, key)}}
            else
              true -> {:cont, {:ok, MapSet.put(seen, key)}}
              Exonerate.Tools.error_match(error) -> {:halt, error}
            end

          _, Exonerate.Tools.error_match(error) ->
            {:halt, error}
        end)
      end
    end
  end

  defp build_seen(call, visitor_call, filters, _) do
    quote do
      defp unquote(call)(object, path, seen) do
        require Exonerate.Tools

        Enum.reduce_while(object, :ok, fn
          {key, value}, :ok ->
            unquote(with_expression(filters, visitor_call))

          _, Exonerate.Tools.error_match(error) ->
            {:halt, error}
        end)
      end
    end
  end

  defp with_expression([], visitor_call) do
    quote do
      result =
        if key in seen do
          :ok
        else
          unquote(visitor_call)(value, Path.join(path, key))
        end

      {:cont, result}
    end
  end

  defp with_expression(filters, visitor_call) do
    quote do
      visited = false

      with unquote_splicing(filters) do
        result =
          if key in seen or visited do
            :ok
          else
            unquote(visitor_call)(value, Path.join(path, key))
          end

        {:cont, result}
      else
        Exonerate.Tools.error_match(error) -> {:halt, error}
      end
    end
  end

  defp build_visited(call, visitor_call, filters, tracked) do
    filters =
      filters ++
        [
          quote do
            false <- visited
          end
        ]

    final_return =
      if tracked do
        quote do
          case do
            :ok ->
              {:ok, MapSet.new(Map.keys(object))}

            error ->
              error
          end
        end
      else
        quote do
          case do
            result -> result
          end
        end
      end

    quote do
      defp unquote(call)(object, path) do
        require Exonerate.Tools

        Enum.reduce_while(object, :ok, fn
          {key, value}, :ok ->
            visited = false

            with unquote_splicing(filters) do
              {:cont, unquote(visitor_call)(value, Path.join(path, key))}
            else
              true -> {:cont, :ok}
              Exonerate.Tools.error_match(error) -> {:halt, error}
            end

          _, Exonerate.Tools.error_match(error) ->
            {:halt, error}
        end)
        |> unquote(final_return)
      end
    end
  end

  defp build_tracked(call, filters) do
    quote do
      defp unquote(call)(object, path) do
        require Exonerate.Tools

        Enum.reduce_while(object, {:ok, MapSet.new()}, fn
          {key, value}, {:ok, seen} ->
            visited = false

            with unquote_splicing(filters) do
              seen =
                if visited do
                  MapSet.put(seen, key)
                else
                  seen
                end

              {:cont, {:ok, seen}}
            else
              true -> {:cont, {:ok, MapSet.put(seen, key)}}
              Exonerate.Tools.error_match(error) -> {:halt, error}
            end

          _, Exonerate.Tools.error_match(error) ->
            {:halt, error}
        end)
      end
    end
  end

  defp build_trivial(call, filters) do
    quote do
      defp unquote(call)(object, path) do
        require Exonerate.Tools

        Enum.reduce_while(object, :ok, fn
          {key, value}, :ok ->
            with unquote_splicing(filters) do
              {:cont, :ok}
            else
              Exonerate.Tools.error_match(error) -> {:halt, error}
            end
        end)
      end
    end
  end

  defmacro accessories(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_accessories(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_accessories(context, resource, pointer, opts) do
    for filter <- @filters, is_map_key(context, filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      opts = adjust_opts(opts, filter, context)

      quote do
        require unquote(module)
        unquote(module).filter(unquote(resource), unquote(pointer), unquote(opts))
      end
    end
  end

  @no_tracked ~w(propertyNames additionalProperties unevaluatedProperties)

  defp adjust_opts(opts, filter, context) do
    opts
    |> Keyword.delete(:only)
    |> Tools.if(needs_tracked?(opts, context), &Keyword.put(&1, :tracked, :object))
    |> Tools.if(filter in @no_tracked, &Keyword.delete(&1, :tracked))
  end

  defp needs_tracked?(opts, context) do
    !!Keyword.get(opts, :tracked, false) or
      (is_map_key(context, "additionalProperties") or is_map_key(context, "unevaluatedProperties"))
  end
end
