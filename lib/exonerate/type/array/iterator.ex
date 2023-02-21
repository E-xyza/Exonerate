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
    "additionalItems" => Exonerate.Filter.AdditionalItems,
    "prefixItems" => Exonerate.Filter.PrefixItems,
    "maxContains" => Exonerate.Filter.MaxContains,
    "minContains" => Exonerate.Filter.MinContains
  }

  @filters Map.keys(@modules)

  def filter_modules, do: @modules
  def filters, do: @filters

  def needed?(schema) do
    Enum.any?(@filters, &is_map_key(schema, &1))
  end

  @find_keys [
    ["contains"],
    ["minItems"],
    ["contains", "minItems"],
    ["contains", "minContains"],
    ["contains", "minContains", "minItems"]
  ]

  @spec mode(Type.json()) :: :find | :filter | nil
  def mode(schema) do
    schema
    |> Map.take(@filters)
    |> adjust_subschema
    |> Map.keys()
    |> Enum.sort()
    |> case do
      [] -> nil
      keys when keys in @find_keys -> :find
      _ -> :filter
    end
  end

  defmacro from_cached(name, pointer, :filter, opts) do
    subschema =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)
      |> adjust_subschema

    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    acc = accumulator(subschema)

    filters = Enum.flat_map(subschema, &filter_for(&1, acc, name, pointer, subschema))

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

  defmacro from_cached(_name, _pointer, nil, _opts), do: []

  # COMMON FUNCTIONS

  defp adjust_subschema(subschema) when not is_map_key(subschema, "contains") do
    Map.drop(subschema, ["maxContains", "minContains"])
  end

  defp adjust_subschema(subschema), do: subschema

  defp accumulator(schema) do
    schema
    |> Map.take(@filters)
    |> Map.keys()
    |> Enum.flat_map(&accumulators_for/1)
    |> Enum.uniq()
  end

  defp accumulators_for("contains"), do: [:contains]
  defp accumulators_for("prefixItems"), do: [:index]
  defp accumulators_for("items"), do: [:index]
  defp accumulators_for("uniqueItems"), do: [:index, :so_far]
  defp accumulators_for("minItems"), do: [:index]
  defp accumulators_for("maxItems"), do: [:index]
  defp accumulators_for(_), do: []

  # FILTER MODE

  defp filter_initializer_for(acc) do
    case acc do
      [:contains] ->
        quote do
          {:ok, 0}
        end

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
              {:contains, 0}

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

      [:contains] ->
        quote do
          {:ok, contains}
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
    case Enum.sort(acc) do
      [:contains] ->
        quote do
          {:cont, {:ok, contains}}
        end

      [:index] ->
        quote do
          {:cont, {:ok, index + 1}}
        end

      [] ->
        {:cont, {:ok, []}}

      list ->
        build_continuation(list)
    end
  end

  defp build_continuation(keys) do
    accumulator_chain =
      Enum.reduce(
        keys,
        quote do
          acc
        end,
        fn
          :index, so_far ->
            quote do
              unquote(so_far)
              |> Map.replace!(:index, acc.index + 1)
            end

          :so_far, so_far ->
            quote do
              unquote(so_far)
              |> Map.replace!(:so_far, MapSet.put(acc.so_far, item))
            end

          :contains, so_far ->
            quote do
              unquote(so_far)
              |> Map.replace!(:contains, acc.contains + 1)
            end
        end
      )

    quote do
      result = unquote(accumulator_chain)
      {:cont, {:ok, result}}
    end
  end

  defp filter_for({"items", list}, acc, name, pointer, _subschema) when is_list(list) do
    call =
      pointer
      |> JsonPointer.traverse("items")
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        :ok <-
          unquote(call)(
            item,
            unquote(index_for(acc)),
            Path.join(path, "#{unquote(index_for(acc))}")
          )
      end
    ]
  end

  defp filter_for({"items", _}, acc, name, pointer, %{"prefixItems" => _}) do
    call =
      pointer
      |> JsonPointer.traverse("items")
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        :ok <-
          unquote(call)(
            item,
            unquote(index_for(acc)),
            Path.join(path, "#{unquote(index_for(acc))}")
          )
      end
    ]
  end

  defp filter_for({"items", _}, acc, name, pointer, _subschema) do
    call =
      pointer
      |> JsonPointer.traverse("items")
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        :ok <- unquote(call)(item, Path.join(path, "#{unquote(index_for(acc))}"))
      end
    ]
  end

  defp filter_for({"prefixItems", list}, acc, name, pointer, _subschema) when is_list(list) do
    call =
      pointer
      |> JsonPointer.traverse("prefixItems")
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        :ok <-
          unquote(call)(
            item,
            unquote(index_for(acc)),
            Path.join(path, "#{unquote(index_for(acc))}")
          )
      end
    ]
  end

  defp filter_for({"contains", _}, [:contains], name, pointer, _subschema) do
    call =
      pointer
      |> JsonPointer.traverse(["contains", ":entrypoint"])
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        contains = unquote(call)(item, path, contains)
      end
    ]
  end

  defp filter_for({"contains", _}, _, name, pointer, _subschema) do
    call =
      pointer
      |> JsonPointer.traverse(["contains", ":entrypoint"])
      |> Tools.pointer_to_fun_name(authority: name)

    [
      quote do
        contains = unquote(call)(item, path, acc.contains)
      end
    ]
  end

  defp filter_for({"uniqueItems", true}, _, _name, pointer, _subschema) do
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

  defp filter_for({"maxItems", count}, [:index], _name, pointer, _subschema) do
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

  defp filter_for({"maxItems", count}, _, _name, pointer, _subschema) do
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

  defp filter_for(_, _, _name, _pointer, _subschema), do: []

  defp index_for([:index]) do
    quote do
      index
    end
  end

  defp index_for([_ | _]) do
    quote do
      acc.index
    end
  end

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
          {Exonerate.Tools.mismatch(content, unquote(JsonPointer.to_uri(contains_pointer)), path),
           0},
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

  defp find_code_for(schema = %{"contains" => _}, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    contains_pointer = JsonPointer.traverse(pointer, "contains")

    contains_call = Tools.pointer_to_fun_name(contains_pointer, authority: name)

    needed = Map.get(schema, "minContains", 1)

    quote do
      def unquote(call)(content, path) do
        require Exonerate.Tools

        content
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(content, unquote(JsonPointer.to_uri(contains_pointer)), path),
           0, 0},
          fn
            item, {{:error, params}, index, count} ->
              case unquote(contains_call)(item, path) do
                error = {:error, _} ->
                  new_params = Keyword.update(params, :failures, [error], &[error | &1])
                  {:cont, {{:error, params}, index + 1, count}}

                :ok when count < unquote(needed - 1) ->
                  {:cont, {{:error, params}, index, count + 1}}

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
