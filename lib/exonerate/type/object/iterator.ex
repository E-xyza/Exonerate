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
    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(pointer)
    |> build_code(name, pointer, opts)
    |> Tools.maybe_dump(opts)
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

    main_call =
      case track_state do
        :tracked ->
          build_tracked(call, final_call, filters)

        :untracked ->
          build_untracked(call, filters)
      end

    quote do
      unquote(main_call)
      unquote(accessories)
      unquote(final_accessory)
    end
  end

  defp build_tracked(call, final_call, filters) do
    quote do
      defp unquote(call)(content, path) do
        Enum.reduce_while(content, :ok, fn
          _, error = {:error, _} ->
            {:halt, error}

          {k, v}, :ok ->
            seen = false

            with unquote_splicing(filters) do
              if seen do
                {:cont, :ok}
              else
                {:cont, unquote(final_call)({k, v}, path)}
              end
            else
              error -> {:halt, error}
            end
        end)
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

  defp filter_for(_, _, _, _) do
    []
  end
end
