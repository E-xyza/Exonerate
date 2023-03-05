defmodule Exonerate.Type.Object.Iterator do
  alias Exonerate.Tools

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

  def fliters, do: @filters

  def needed?(context) do
    Enum.any?(@filters, &is_map_key(context, &1))
  end

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, authority, pointer, opts) do
    call = Tools.call(authority, JsonPointer.join(pointer, ":iterator"), opts)
    visitor_call = visitor_call(context, authority, pointer, opts)

    filters =
      for filter <- @iterators, is_map_key(context, filter), reduce: [] do
        acc ->
          filter_call = Tools.call(authority, JsonPointer.join(pointer, filter), opts)

          if filter in @visited and visitor_call do
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

    if visitor_call do
      build_visited(call, visitor_call, filters)
    else
      build_no_visted(call, filters)
    end
  end

  defp visitor_call(context, authority, pointer, opts) do
    case context do
      %{"additionalProperties" => _} ->
        Tools.call(authority, JsonPointer.join(pointer, "additionalProperties"), opts)

      %{"unevaluatedProperties" => _} ->
        Tools.call(authority, JsonPointer.join(pointer, "unevaluatedProperties"), opts)

      _ ->
        nil
    end
  end

  defp build_visited(call, visitor_call, filters) do
    quote do
      defp unquote(call)(object, path) do
        Enum.reduce_while(object, :ok, fn
          _, error = {:error, _} ->
            {:halt, error}

          {key, value}, :ok ->
            visited = false

            with unquote_splicing(filters) do
              result =
                if visited do
                  :ok
                else
                  unquote(visitor_call)(value, Path.join(path, key))
                end

              {:cont, result}
            else
              error -> {:halt, error}
            end
        end)
      end
    end
  end

  defp build_no_visted(call, filters) do
    quote do
      defp unquote(call)(object, path) do
        Enum.reduce_while(object, :ok, fn
          {key, value}, :ok ->
            with unquote_splicing(filters) do
              {:cont, :ok}
            else
              error -> {:halt, error}
            end
        end)
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
    for filter <- @filters, is_map_key(context, filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      opts =
        if filter in @visited and visitor_call(context, authority, pointer, opts) do
          Keyword.put(opts, :visited, true)
        else
          opts
        end

      quote do
        require unquote(module)
        unquote(module).filter(unquote(authority), unquote(pointer), unquote(opts))
      end
    end
  end
end
