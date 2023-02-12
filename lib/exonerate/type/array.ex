defmodule Exonerate.Type.Array do
  alias Exonerate.Tools

  @modules %{
    "items" => Exonerate.Filter.Items,
    "contains" => Exonerate.Filter.Contains,
    "uniqueItems" => Exonerate.Filter.UniqueItems,
    "minItems" => Exonerate.Filter.MinItems,
    "maxItems" => Exonerate.Filter.MaxItems
  }

  @filters Map.keys(@modules)

  # TODO: consider making a version where we don't bother indexing, if it's not necessary.

  def filter(schema, name, pointer) do
    subschema = JsonPointer.resolve!(schema, pointer)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    case Map.take(subschema, @filters) do
      empty when map_size(empty) === 0 ->
        quote do
          defp unquote(call)(content, _path) when is_list(content) do
            :ok
          end
        end

      _ ->
        class = class_for(subschema)
        filters = filter_calls(subschema, class, name, pointer)

        quote do
          defp unquote(call)(content, path) when is_list(content) do
            content
            |> Enum.reduce_while(unquote(initializer_for(class, pointer)), fn
              item, unquote(accumulator_for(class)) ->
                with unquote_splicing(filters) do
                  unquote(continuation_for(class))
                else
                  halt -> {:halt, {halt, []}}
                end
            end)
            |> unquote(analysis_for(subschema, class, pointer))
          end
        end
    end
  end

  defp class_for(schema) do
    schema
    |> Map.take(@filters)
    |> Map.keys()
    |> Enum.flat_map(&accumulators_for/1)
    |> Enum.uniq()
  end

  defp accumulators_for("contains"), do: [:contains]
  defp accumulators_for("items"), do: [:index]
  defp accumulators_for("uniqueItems"), do: [:so_far, :index]
  defp accumulators_for("minItems"), do: [:index]
  defp accumulators_for("maxItems"), do: [:index]
  defp accumulators_for(_), do: []

  defp initializer_for(class, pointer) do
    case class do
      # note that "contains" is inverted, we'll generate the error first
      # and then halt on :ok
      [:contains] ->
        schema_pointer =
          pointer
          |> JsonPointer.traverse("contains")
          |> JsonPointer.to_uri()

        quote do
          require Exonerate.Tools
          {Exonerate.Tools.mismatch(content, unquote(schema_pointer), path), []}
        end

      [:index] ->
        {:ok, 0}

      [] ->
        :ok

      list ->
        init =
          list
          |> Map.new(fn
            :so_far -> {:so_far, MapSet.new()}
            :index -> {:index, 0}
          end)
          |> Macro.escape()

        {:ok, init}
    end
  end

  defp accumulator_for(class) do
    case class do
      [:contains] ->
        quote do
          error
        end

      [:index] ->
        quote do
          {:ok, index}
        end

      [] ->
        quote do
          _
        end

      _ ->
        quote do
          {:ok, acc}
        end
    end
  end

  defp continuation_for(class) do
    case class do
      [:contains] ->
        quote do
          {:cont, error}
        end

      [:index] ->
        quote do
          {:cont, {:ok, index + 1}}
        end

      [] ->
        {:cont, {:ok, []}}

      [:so_far, :index] ->
        # TODO: do better at generalizing this
        quote do
          {:cont, {:ok, %{acc | index: acc.index + 1, so_far: MapSet.put(acc.so_far, item)}}}
        end
    end
  end

  defp filter_calls(schema, class, name, pointer) do
    case Map.take(schema, @filters) do
      empty when empty === %{} ->
        []

      filters ->
        build_filters(filters, class, name, pointer)
    end
  end

  defp build_filters(filters, class, name, pointer) do
    Enum.flat_map(filters, &filter_for(&1, class, name, pointer))
  end

  defp filter_for({"items", list}, _class, name, pointer) when is_list(list) do
    call =
      pointer
      |> JsonPointer.traverse("items")
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        :ok <- unquote(call)(item, index, Path.join(path, "#{index}"))
      end
    ]
  end

  defp filter_for({"items", _}, _class, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse("items")
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        :ok <- unquote(call)(item, Path.join(path, "#{index}"))
      end
    ]
  end

  defp filter_for({"contains", _}, [:contains], name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse("contains")
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        {:error, _} <- unquote(call)(item, Path.join(path, ":any"))
      end
    ]
  end

  defp filter_for({"uniqueItems", true}, _, _name, pointer) do
    pointer =
      pointer
      |> JsonPointer.traverse("uniqueItems")
      |> JsonPointer.to_uri()

    [
      quote do
        nil <-
          if item in acc.so_far do
            require Exonerate.Tools
            Exonerate.Tools.mismatch(item, unquote(pointer), Path.join(path, "#{acc.index}"))
          end
      end
    ]
  end

  defp filter_for({"minItems", _}, _, _name, _pointer), do: []

  defp filter_for({"maxItems", count}, [:index], _name, pointer) do
    pointer =
      pointer
      |> JsonPointer.traverse("maxItems")
      |> JsonPointer.to_uri()

    [
      quote do
        nil <-
          if index >= unquote(count) do
            require Exonerate.Tools
            Exonerate.Tools.mismatch(content, unquote(pointer), path)
          end
      end
    ]
  end

  defp filter_for({"maxItems", count}, _, _name, pointer) do
    pointer =
      pointer
      |> JsonPointer.traverse("maxItems")
      |> JsonPointer.to_uri()

    [
      quote do
        nil <-
          if acc.index >= unquote(count) do
            require Exonerate.Tools
            Exonerate.Tools.mismatch(content, unquote(pointer), path)
          end
      end
    ]
  end

  defp analysis_for(%{"minItems" => count}, [:index], pointer) do
    pointer =
      pointer
      |> JsonPointer.traverse("minItems")
      |> JsonPointer.to_uri()

    quote do
      then(fn
        {:ok, deficient} when deficient < unquote(count) - 1 ->
          require Exonerate.Tools
          Exonerate.Tools.mismatch(content, unquote(pointer), path)

        {:ok, _} ->
          :ok

        {error = {:error, _}, _} ->
          error
      end)
    end
  end

  defp analysis_for(%{"minItems" => count}, _class, pointer) do
    pointer =
      pointer
      |> JsonPointer.traverse("minItems")
      |> JsonPointer.to_uri()

    quote do
      then(fn
        {:ok, %{index: deficient}} when deficient < unquote(count) - 1 ->
          require Exonerate.Tools
          Exonerate.Tools.mismatch(content, unquote(pointer), path)

        other ->
          other
      end)
    end
  end

  defp analysis_for(schema, _class, _pointer) do
    quote do
      elem(0)
    end
  end

  def accessories(schema, name, pointer, opts) do
    for filter_name <- @filters, Map.has_key?(schema, filter_name) do
      list_accessory(filter_name, schema, name, pointer, opts)
    end
  end

  defp list_accessory(filter_name, _schema, name, pointer, opts) do
    module = @modules[filter_name]
    pointer = JsonPointer.traverse(pointer, filter_name)

    quote do
      require unquote(module)
      unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
