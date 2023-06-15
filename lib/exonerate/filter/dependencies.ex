defmodule Exonerate.Filter.Dependencies do
  @moduledoc false

  alias Exonerate.Context
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> Enum.map(&make_dependencies(&1, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp make_dependencies({key, subschema}, resource, pointer, opts) do
    call = Tools.call(resource, JsonPtr.join(pointer, key), :entrypoint, opts)

    prong =
      quote do
        :ok <- unquote(call)(content, path)
      end

    {prong, accessory(call, key, subschema, resource, pointer, opts)}
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

  defp accessory(call, key, deps_list, resource, pointer, _opts) when is_list(deps_list) do
    prongs =
      Enum.with_index(deps_list, fn
        dependent_key, index ->
          schema_pointer = JsonPtr.join(pointer, [key, "#{index}"])

          quote do
            :ok <-
              if is_map_key(content, unquote(dependent_key)) do
                :ok
              else
                require Exonerate.Tools

                Exonerate.Tools.mismatch(
                  content,
                  unquote(resource),
                  unquote(schema_pointer),
                  path
                )
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

  defp accessory(call, key, subschema, resource, pointer, opts)
       when is_map(subschema) or is_boolean(subschema) do
    pointer = JsonPtr.join(pointer, key)
    context_opts = Context.scrub_opts(opts)
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
