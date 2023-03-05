defmodule Exonerate.Type.Object.Iterator do
  alias Exonerate.Tools

  # Note that we don't need

  @iterator_modules %{
    "properties" => Exonerate.Filter.Properties,
    "propertyNames" => Exonerate.Filter.PropertyNames,
    "patternProperties" => Exonerate.Filter.PatternProperties
  }

  @iterators Map.keys(@iterator_modules)

  @finalizer_modules %{
    "additionalProperties" => Exonerate.Filter.AdditionalProperties,
    "unevaluatedProperties" => Exonerate.Filter.UnevaluatedProperties
  }

  @finalizers Map.keys(@finalizer_modules)

  @filters @iterators ++ @finalizers
  @modules Map.merge(@iterator_modules, @finalizer_modules)

  def fliters, do: @filters

  def needed?(schema) do
    Enum.any?(@filters, &is_map_key(schema, &1))
  end

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(schema, authority, pointer, opts) do
    call = Tools.call(authority, JsonPointer.join(pointer, ":iterator"), opts)

    filters =
      for filter <- @iterators, is_map_key(schema, filter) do
        filter_call = Tools.call(authority, JsonPointer.join(pointer, filter), opts)

        quote do
          :ok <- unquote(filter_call)({key, value}, path)
        end
      end

    build_untracked(call, filters)
  end

  defp build_untracked(call, filters) do
    quote do
      defp unquote(call)(object, path) do
        alias Exonerate.Combining
        require Combining

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

  defp build_accessories(context, name, pointer, opts) do
    for filter <- @filters, is_map_key(context, filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      quote do
        require unquote(module)
        unquote(module).filter(unquote(name), unquote(pointer), unquote(opts))
      end
    end
  end
end
