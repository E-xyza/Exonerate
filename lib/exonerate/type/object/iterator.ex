defmodule Exonerate.Type.Object.Iterator do
  alias Exonerate.Cache
  alias Exonerate.Combining
  alias Exonerate.Tools

  @modules %{
    "properties" => Exonerate.Filter.Properties,
    "additionalProperties" => Exonerate.Filter.AdditionalProperties,
    "unevaluatedProperties" => Exonerate.Filter.UnevaluatedProperties,
    "propertyNames" => Exonerate.Filter.PropertyNames,
    "patternProperties" => Exonerate.Filter.PatternProperties
  }

  @filters Map.keys(@modules)

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
    outer_tracked = Keyword.get(opts, :track_properties, false)

    call =
      pointer
      |> JsonPointer.join(":iterator")
      |> Tools.if(outer_tracked, &JsonPointer.join(&1, ":tracked"))
      |> Tools.pointer_to_fun_name(authority: name)

    # NOTE: we can't count on this working properly with the outer_tracked variable
    # beacuse outer_tracked describes the internal code structure and overloads the
    # :additional tag for trivial unevaluated cases.
    {final_call, final_accessory} =
      case schema do
        %{"additionalProperties" => _} ->
          pointer = JsonPointer.join(pointer, "additionalProperties")
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

          {final_call, final_accessory}

        %{"unevaluatedProperties" => _} ->
          pointer = JsonPointer.join(pointer, "unevaluatedProperties")
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

          {final_call, final_accessory}

        _ ->
          {nil, []}
      end

    {filters, accessories} =
      schema
      |> Map.take(@filters)
      |> Enum.flat_map(&filter_for(&1, name, pointer, opts))
      |> Enum.unzip()

    # build the main call in three different cases:
    # - needs additionalProperties
    # - needs unevaluatedProperties
    # - trivial
    main_call =
      case {opts[:internal_tracking],
            Enum.find_value(filters, &(elem(&1, 0) === :error and elem(&1, 1)))} do
        {:additional, nil} ->
          build_additional(call, final_call, filters, outer_tracked)

        {:unevaluated, nil} ->
          build_unevaluated(call, final_call, filters, outer_tracked)

        {nil, nil} ->
          build_untracked(call, filters, outer_tracked)

        {_, error_path} ->
          build_trivial(call, pointer, error_path, outer_tracked)
      end

    quote do
      unquote(main_call)
      unquote(accessories)
      unquote(final_accessory)
    end
  end

  defp build_additional(call, final_call, [], outer_tracked) do
    quote do
      defp unquote(call)(content, path) do
        alias Exonerate.Combining
        require Combining

        Enum.reduce_while(content, Combining.initialize(unquote(outer_tracked)), fn
          {key, value}, Combining.capture(unquote(outer_tracked), seen) ->
            case unquote(final_call)(value, Path.join(path, key)) do
              :ok -> {:cont, Combining.update_key(unquote(outer_tracked), seen, key)}
              error = {:error, _} -> {:halt, error}
            end
        end)
      end
    end
  end

  defp build_additional(call, final_call, filters, outer_tracked) do
    quote do
      defp unquote(call)(content, path) do
        alias Exonerate.Combining
        require Combining

        Enum.reduce_while(content, Combining.initialize(unquote(outer_tracked)), fn
          _, error = {:error, _} ->
            {:halt, error}

          {key, value}, Combining.capture(unquote(outer_tracked), seen) ->
            unquote(tracked_with(final_call, filters, outer_tracked))
        end)
      end
    end
  end

  defp build_unevaluated(call, final_call, [], outer_tracked) do
    quote do
      defp unquote(call)(content, path, seen) do
        alias Exonerate.Combining
        require Combining

        Enum.reduce_while(content, Combining.initialize(unquote(outer_tracked)), fn
          {key, value}, Combining.capture(unquote(outer_tracked), seen) ->
            if key in seen do
              {:cont, Combining.capture(unquote(outer_tracked), seen)}
            else
              case unquote(make_final_call(final_call)) do
                :ok -> {:cont, Combining.update_key(unquote(outer_tracked), seen, key)}
                error = {:error, _} -> {:halt, error}
              end
            end
        end)
      end
    end
  end

  defp build_unevaluated(call, final_call, filters, outer_tracked) do
    quote do
      defp unquote(call)(content, path, seen) do
        alias Exonerate.Combining
        require Combining

        Enum.reduce_while(content, Combining.initialize(unquote(outer_tracked)), fn
          _, error = {:error, _} ->
            {:halt, error}

          {key, value}, Combining.capture(unquote(outer_tracked), seen) ->
            unquote(tracked_with(final_call, filters, outer_tracked))
        end)
      end
    end
  end

  defp tracked_with(final_call, filters, outer_tracked) do
    quote do
      seen = false

      with unquote_splicing(filters) do
        if seen do
          {:cont, Combining.update_key(unquote(outer_tracked), seen, key)}
        else
          {:cont, unquote(make_final_call(final_call))}
        end
      else
        error -> {:halt, error}
      end
    end
  end

  defp make_final_call(nil) do
    quote do
      {:ok, seen}
    end
  end

  defp make_final_call(call) do
    quote do
      unquote(call)(value, Path.join(path, key))
    end
  end

  defp build_untracked(call, filters, outer_tracked) do
    quote do
      defp unquote(call)(content, path) do
        alias Exonerate.Combining
        require Combining

        Enum.reduce_while(content, Combining.initialize(unquote(outer_tracked)), fn
          {key, value}, Combining.capture(unquote(outer_tracked), seen) ->
            with unquote_splicing(filters) do
              {:cont, Combining.update_key(unquote(outer_tracked), seen, key)}
            else
              error -> {:halt, error}
            end
        end)
      end
    end
  end

  defp build_trivial(call, pointer, error_path, outer_tracked) do
    schema_pointer =
      pointer
      |> JsonPointer.join(error_path)
      |> JsonPointer.to_uri()

    result =
      if outer_tracked do
        quote do
          {:ok, content |> Map.keys() |> MapSet.new()}
        end
      else
        :ok
      end

    quote do
      defp unquote(call)(content, path) do
        case map_size(content) do
          0 ->
            unquote(result)

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
        end
      end
    end
  end

  defp filter_for({"properties", _}, name, pointer, opts) do
    pointer = JsonPointer.join(pointer, "properties")
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    tracked = Keyword.get(opts, :track_properties, false)

    filter =
      cond do
        opts[:internal_tracking] === :additional ->
          quote do
            {:ok, seen} <- unquote(call)({key, value}, path, seen)
          end

        true ->
          quote do
            :ok <- unquote(call)({key, value}, path)
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
    pointer = JsonPointer.join(pointer, "patternProperties")
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    tracked = Keyword.get(opts, :track_properties, false)

    filter =
      cond do
        opts[:internal_tracking] === :additional ->
          quote do
            {:ok, seen} <- unquote(call)({key, value}, path, seen)
          end

        true ->
          quote do
            :ok <- unquote(call)({key, value}, path)
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

  # note that having propertyNames is incompatible with any outer_tracked
  # parameters.
  defp filter_for({"propertyNames", subschema}, name, pointer, opts) do
    pointer = JsonPointer.join(pointer, "propertyNames")
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    filter =
      case opts[:tracker] do
        nil ->
          quote do
            :ok <- unquote(call)(key, Path.join(path, key))
          end
      end

    subschema
    |> Tools.degeneracy()
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
             unquote(Tools.drop_tracking(opts))
           )
         end}
    end
    |> List.wrap()
  end

  defp filter_for(_, _, _, _) do
    []
  end
end
