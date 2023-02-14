defmodule Exonerate.Type.Array.Iterator do
  @moduledoc false

  # note that iteration can go in two different modes, "find" vs "filter". In
  # "filter" mode, the iteration will occur with the same objective as most
  # JsonSchema logic -- when an error is encountered, it terminates and
  # reports this error as the result.  In "find" mode, error is assumed and
  # the looping terminates when a passing result is found, this only applies
  # to "minItems" and "contains" filters.

  alias Exonerate.Cache
  alias Exonerate.Tools
  alias Exonerate.Type

  @modules %{
    "items" => Exonerate.Filter.Items,
    "contains" => Exonerate.Filter.Contains,
    "uniqueItems" => Exonerate.Filter.UniqueItems,
    "minItems" => Exonerate.Filter.MinItems,
    "maxItems" => Exonerate.Filter.MaxItems,
    "additionalItems" => Exonerate.Filter.AdditionalItems
  }

  @filters Map.keys(@modules)

  def filter_modules, do: @modules
  def filters, do: @filters

  def needed?(schema) do
    Enum.any?(@filters, &is_map_key(schema, &1))
  end

  @spec mode(Type.json()) :: :find | :filter | nil
  def mode(schema) do
    schema
    |> Map.take(@filters)
    |> Map.keys()
    |> Enum.sort()
    |> case do
      [] -> nil
      ["contains"] -> :find
      ["minItems"] -> :find
      ["contains", "minItems"] -> :find
      _ -> :filter
    end
  end

  defmacro from_cached(name, pointer, :filter, opts) do
    subschema =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)

    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    acc = accumulator(subschema)

    filters = Enum.flat_map(subschema, &filter_for(&1, acc, name, pointer))

    Tools.maybe_dump(
      quote do
        def unquote(call)(content, path) do
          content
          |> Enum.reduce_while(unquote(filter_initializer_for(acc)), fn
            item, unquote(filter_accumulator_for(acc)) ->
              with unquote_splicing(filters) do
                unquote(filter_continuation_for(acc))
              else
                error = {:error, _} -> {:halt, {error, []}}
              end
          end)
          |> unquote(filter_analysis_for(subschema, acc, pointer))
        end
      end,
      opts
    )
  end

  defmacro from_cached(name, pointer, :find, opts) do
    subschema =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)

    subschema
    |> find_code_for(name, pointer)
    |> Tools.maybe_dump(opts)
  end

  # COMMON FUNCTIONS

  defp accumulator(schema) do
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

  # FILTER MODE

  defp filter_initializer_for(acc) do
    case acc do
      [:index] ->
        {:ok, 0}

      [:so_far] ->
        {:ok,
         quote do
           MapSet.new()
         end}

      [] ->
        :ok

      list ->
        init =
          Enum.map(list, fn
            :contains ->
              {:contains, false}

            :so_far ->
              {:so_far,
               quote do
                 MapSet.new()
               end}

            :index ->
              {:index, 0}
          end)

        {:ok, {:%{}, [], init}}
    end
  end

  defp filter_accumulator_for(acc) do
    case acc do
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

  defp filter_continuation_for(acc) do
    case acc do
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

  defp filter_for({"items", list}, _acc, name, pointer) when is_list(list) do
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

  defp filter_for({"items", _}, _acc, name, pointer) do
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

  defp filter_for(_, _, _name, _pointer), do: []

  defp filter_analysis_for(%{"minItems" => count}, [:index], pointer) do
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

  defp filter_analysis_for(%{"minItems" => count}, _acc, pointer) do
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

  defp filter_analysis_for(_schema, _acc, _pointer) do
    quote do
      elem(0)
    end
  end

  # FIND MODE
  # since these don't have to be generic, go ahead and write out all three cases by hand.

  defp find_code_for(%{"contains" => _, "minItems" => length}, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    contains_pointer = JsonPointer.traverse(pointer, "contains")

    min_items_pointer =
      pointer
      |> JsonPointer.traverse("minItems")
      |> JsonPointer.to_uri()

    contains_call = Tools.pointer_to_fun_name(contains_pointer, authority: name)

    quote do
      def unquote(call)(content, path) do
        require Exonerate.Tools

        content
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(content, unquote(JsonPointer.to_uri(contains_pointer)), path), 0},
          fn
            _item, {:ok, index} when index >= unquote(length) ->
              {:halt, {:ok, index}}

            _item, {:ok, index} when index < unquote(length) - 1 ->
              {:cont, {:ok, index + 1}}

            item, {{:error, params}, index} ->
              with error = {:error, _} <- unquote(contains_call)(item, path) do
                new_params = Keyword.update(params, :failures, [error], &[error | &1])
                {:cont, {{:error, params}, index + 1}}
              else
                :ok ->
                  {:cont, {:ok, index + 1}}
              end
          end
        )
        |> case do
          {:ok, index} when index < unquote(length) - 1 ->
            Exonerate.Tools.mismatch(content, unquote(min_items_pointer), path)

          {error = {:error, _}, _} ->
            error
        end
      end
    end
  end

  defp find_code_for(%{"contains" => _}, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    contains_pointer = JsonPointer.traverse(pointer, "contains")

    contains_call = Tools.pointer_to_fun_name(contains_pointer, authority: name)

    quote do
      def unquote(call)(content, path) do
        require Exonerate.Tools

        content
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(content, unquote(JsonPointer.to_uri(contains_pointer)), path), 0},
          fn
            item, {{:error, params}, index} ->
              with error = {:error, _} <- unquote(contains_call)(item, path) do
                new_params = Keyword.update(params, :failures, [error], &[error | &1])
                {:cont, {{:error, params}, index + 1}}
              else
                :ok ->
                  {:halt, {:ok, []}}
              end
          end
        )
        |> elem(0)
      end
    end
  end

  defp find_code_for(%{"minItems" => length}, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    min_items_pointer =
      pointer
      |> JsonPointer.traverse("minItems")
      |> JsonPointer.to_uri()

    quote do
      def unquote(call)(content, path) do
        require Exonerate.Tools

        content
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(content, unquote(min_items_pointer), path), 0},
          fn
            _item, {error, index} when index < unquote(length - 1) ->
              {:cont, {error, index + 1}}

            _item, {error, index} ->
              {:halt, {:ok, []}}
          end
        )
        |> elem(0)
      end
    end
  end

  # ACCESSORIES
  def accessories(schema, name, pointer, opts) do
    # this only is necessary if we have *any* iterated feature, and creates
    # the single :iterator accessory.
    List.wrap(
      if Enum.any?(@filters, &is_map_key(schema, &1)) do
        mode = mode(schema)

        quote do
          require Exonerate.Type.Array.Iterator

          Exonerate.Type.Array.Iterator.from_cached(
            unquote(name),
            unquote(pointer),
            unquote(mode),
            unquote(opts)
          )
        end
      end
    )
  end
end
