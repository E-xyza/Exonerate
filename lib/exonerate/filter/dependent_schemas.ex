defmodule Exonerate.Filter.DependentSchemas do
  @moduledoc false

  # NB "dependentSchemas" is just a repackaging of "dependencies" except only permitting the
  # maps (specification of full schema to be applied to the object)

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> Enum.map(&prong_and_accessory(&1, authority, pointer, opts))
    |> Enum.unzip()
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp prong_and_accessory({key, _schema}, authority, pointer, opts) do
    call = Tools.call(authority, JsonPointer.join(pointer, [key, ":entrypoint"]), opts)

    prong =
      quote do
        :ok <- unquote(call)(content, path)
      end

    accessory = accessory(call, key, authority, pointer, opts)

    {prong, accessory}
  end

  defp accessory(call, key, authority, pointer, opts) do
    pointer = JsonPointer.join(pointer, key)
    inner_call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(content, path) when is_map_key(content, unquote(key)) do
        unquote(inner_call)(content, path)
      end

      defp unquote(call)(content, path), do: :ok

      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
    end
  end

  defp build_filter({prongs, accessories}, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    quote do
      defp unquote(call)(content, path) do
        with unquote_splicing(prongs) do
          :ok
        end
      end

      unquote(accessories)
    end
  end
end
