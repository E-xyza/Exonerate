defmodule Exonerate.Filter.Dependencies do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> Enum.map(&make_dependencies(&1, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp make_dependencies({key, schema}, resource, pointer, opts) do
    call = Tools.call(resource, JsonPointer.join(pointer, key), :entrypoint, opts)

    prong =
      quote do
        :ok <- unquote(call)(content, path)
      end

    {prong, accessory(call, key, schema, resource, pointer, opts)}
  end

  defp build_filter({prongs, accessories}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(content, path) do
        with unquote_splicing(prongs) do
          :ok
        end
      end

      unquote(accessories)
    end
  end

  defp accessory(call, key, schema, _name, pointer, _opts) when is_list(schema) do
    prongs =
      Enum.with_index(schema, fn
        dependent_key, index ->
          schema_pointer = JsonPointer.join(pointer, [key, "#{index}"])

          quote do
            :ok <-
              if is_map_key(content, unquote(dependent_key)) do
                :ok
              else
                require Exonerate.Tools
                Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
              end
          end
      end)

    quote do
      defp unquote(call)(content, path) when is_map_key(content, unquote(key)) do
        with unquote_splicing(prongs) do
          :ok
        end
      end

      defp unquote(call)(content, path), do: :ok
    end
  end

  defp accessory(call, key, schema, resource, pointer, opts)
       when is_map(schema) or is_boolean(schema) do
    pointer = JsonPointer.join(pointer, key)
    context_opts = Tools.scrub(opts)
    context_call = Tools.call(resource, pointer, context_opts)

    quote do
      defp unquote(call)(content, path) when is_map_key(content, unquote(key)) do
        unquote(context_call)(content, path)
      end

      defp unquote(call)(content, path), do: :ok

      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(context_opts))
    end
  end
end
