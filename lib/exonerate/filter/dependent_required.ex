defmodule Exonerate.Filter.DependentRequired do
  # note that dependentRequired is a repackaging of the legacy "dependencies" but only
  # permitting the array form, which is deprecated in later drafts of JsonSchema

  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> Enum.map(&make_prong_and_accessory(&1, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp make_prong_and_accessory({key, subschema}, resource, pointer, opts) do
    call = Tools.call(resource, JsonPointer.join(pointer, key), :entrypoint, opts)

    prong =
      quote do
        :ok <- unquote(call)(content, path)
      end

    accessory = accessory(call, key, subschema, pointer)

    {prong, accessory}
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

  defp accessory(call, key, deps_list, pointer) when is_list(deps_list) do
    prongs =
      Enum.with_index(deps_list, fn
        dependent_key, index ->
          pointer = JsonPointer.join(pointer, [key, "#{index}"])

          quote do
            :ok <-
              if is_map_key(content, unquote(dependent_key)) do
                :ok
              else
                require Exonerate.Tools
                Exonerate.Tools.mismatch(content, unquote(pointer), path)
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
end
