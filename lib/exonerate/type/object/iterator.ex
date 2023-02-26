defmodule Exonerate.Type.Object.Iterator do
  alias Exonerate.Cache
  alias Exonerate.Tools

  @modules %{
    "properties" => Exonerate.Filter.Properties,
    "additionalProperties" => Exonerate.Filter.AdditionalProperties,
    "propertyNames" => Exonerate.Filter.PropertyNames,
    "patternProperties" => Exonerate.Filter.PatternProperties
  }

  @filters Map.keys(@modules)

  def needs_iterator?(subschema) do
    Enum.any?(@filters, &is_map_key(subschema, &1))
  end

  defmacro from_cached(name, pointer, opts) do
    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> build_code(name, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # as an optimization, remove filters that are impossible given other filters.
  defp build_code(schema = %{"propertyNames" => _}, name, pointer, opts)
       when is_map_key(schema, "additionalProperties") or
              is_map_key(schema, "unevaluatedProperties") do
    schema
    |> Map.drop(["additionalProperties", "unevaluatedProperties"])
    |> build_code(name, pointer, opts)
  end

  defp build_code(schema, name, pointer, opts) do
    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    {track_state, final_call, final_accessory} =
      case schema do
        %{"additionalProperties" => _} ->
          pointer = JsonPointer.traverse(pointer, "additionalProperties")
          final_call = Tools.pointer_to_fun_name(pointer, authority: name)

          final_accessory =
            quote do
              require Exonerate.Filter.AdditionalProperties

              Exonerate.Filter.AdditionalProperties.filter_from_cached(
                unquote(name),
                unquote(pointer),
                unquote(opts)
              )
            end

          {:tracked, final_call, final_accessory}

        %{"unevaluatedProperties" => _} ->
          pointer = JsonPointer.traverse(pointer, "unevaluatedProperties")
          final_call = Tools.pointer_to_fun_name(pointer, authority: name)

          final_accessory =
            quote do
              require Exonerate.Filter.UnevaluatedProperties

              Exonerate.Filter.UnevaluatedProperties.filter_from_cached(
                unquote(name),
                unquote(pointer),
                unquote(opts)
              )
            end

          {:tracked, final_call, final_accessory}

        _ ->
          {:untracked, nil, []}
      end

    {filters, accessories} =
      schema
      |> Map.take(@filters)
      |> Enum.flat_map(&filter_for(&1, name, pointer, Keyword.put(opts, :tracker, track_state)))
      |> Enum.unzip()

    # build the main call in three different cases:
    # - empty
    # - tracked
    # - untracked
    # - trivial
    main_call =
      case {filters, track_state,
            Enum.find_value(filters, &(elem(&1, 0) === :error and elem(&1, 1)))} do
        {[], _, _} ->
          build_empty(call, final_call)

        {_, :tracked, nil} ->
          build_tracked(call, final_call, filters)

        {_, :untracked, nil} ->
          build_untracked(call, filters)

        {_, _, error_path} ->
          build_trivial(call, pointer, error_path)
      end

    quote do
      unquote(main_call)
      unquote(accessories)
      unquote(final_accessory)
    end
  end

  defp build_empty(call, final_call) do
    if final_call do
      quote do
        defp unquote(call)(content, path) do
          Enum.reduce_while(content, :ok, fn
            {k, v}, _acc ->
              case unquote(final_call)(v, Path.join(path, k)) do
                :ok -> {:cont, :ok}
                error = {:error, _} -> {:halt, error}
              end
          end)
        end
      end
    else
      quote do
        defp unquote(call)(content, path), do: :ok
      end
    end
  end

  defp build_tracked(call, final_call, filters) do
    quote do
      defp unquote(call)(content, path) do
        Enum.reduce_while(content, :ok, fn
          _, error = {:error, _} ->
            {:halt, error}

          {k, v}, :ok ->
            unquote(tracked_with(final_call, filters))
        end)
      end
    end
  end

  defp tracked_with(final_call, filters) do
    quote do
      seen = false

      with unquote_splicing(filters) do
        if seen do
          {:cont, :ok}
        else
          {:cont, unquote(final_call)(v, Path.join(path, k))}
        end
      else
        error -> {:halt, error}
      end
    end
  end

  defp build_untracked(call, filters) do
    quote do
      defp unquote(call)(content, path) do
        Enum.reduce_while(content, :ok, fn
          {k, v}, :ok ->
            with unquote_splicing(filters) do
              {:cont, :ok}
            else
              error -> {:halt, error}
            end
        end)
      end
    end
  end

  defp build_trivial(call, pointer, error_path) do
    schema_pointer =
      pointer
      |> JsonPointer.traverse(error_path)
      |> JsonPointer.to_uri()

    quote do
      defp unquote(call)(content, path) do
        case map_size(content) do
          0 ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
        end
      end
    end
  end

  defp filter_for({"properties", _}, name, pointer, opts) do
    pointer = JsonPointer.traverse(pointer, "properties")
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    filter =
      case opts[:tracker] do
        :tracked ->
          quote do
            {:ok, seen} <- unquote(call)({k, v}, path, seen)
          end

        :untracked ->
          quote do
            :ok <- unquote(call)({k, v}, path)
          end
      end

    [
      {filter,
       quote do
         require Exonerate.Filter.Properties

         Exonerate.Filter.Properties.filter_from_cached(
           unquote(name),
           unquote(pointer),
           unquote(opts)
         )
       end}
    ]
  end

  defp filter_for({"patternProperties", _}, name, pointer, opts) do
    pointer = JsonPointer.traverse(pointer, "patternProperties")
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    filter =
      case opts[:tracker] do
        :tracked ->
          quote do
            {:ok, seen} <- unquote(call)({k, v}, path, seen)
          end

        :untracked ->
          quote do
            :ok <- unquote(call)({k, v}, path)
          end
      end

    [
      {filter,
       quote do
         require Exonerate.Filter.PatternProperties

         Exonerate.Filter.PatternProperties.filter_from_cached(
           unquote(name),
           unquote(pointer),
           unquote(opts)
         )
       end}
    ]
  end

  # note that having propertyNames is incompatible with any tracked
  # parameters.
  defp filter_for({"propertyNames", subschema}, name, pointer, opts) do
    pointer = JsonPointer.traverse(pointer, "propertyNames")
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    filter =
      case opts[:tracker] do
        :untracked ->
          quote do
            :ok <- unquote(call)(k, Path.join(path, k))
          end
      end

    subschema
    |> Tools.determined()
    |> case do
      :ok ->
        nil

      :error ->
        {{:error, "propertyNames"}, []}

      :unknown ->
        {filter,
         quote do
           require Exonerate.Filter.PropertyNames

           Exonerate.Filter.PropertyNames.filter_from_cached(
             unquote(name),
             unquote(pointer),
             unquote(opts)
           )
         end}
    end
    |> List.wrap()
  end

  defp filter_for(_, _, _, _) do
    []
  end
end
