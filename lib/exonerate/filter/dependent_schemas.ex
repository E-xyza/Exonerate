defmodule Exonerate.Filter.DependentSchemas do
  @moduledoc false

  # NB "dependentSchemas" is just a repackaging of "dependencies" except only permitting the
  # maps (specification of full schema to be applied to the object)

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve_json!(pointer)
    |> Enum.map(&make_dependencies(&1, name, pointer, opts))
    |> Enum.unzip()
    |> build_filter(name, pointer)
    |> Tools.maybe_dump(opts)
  end

  defp make_dependencies({key, schema}, name, pointer, opts) do
    call =
      pointer
      |> JsonPointer.join([key, ":entrypoint"])
      |> Tools.pointer_to_fun_name(authority: name)

    {quote do
       :ok <- unquote(call)(content, path)
     end, accessory(call, key, schema, name, pointer, opts)}
  end

  defp build_filter({prongs, accessories}, name, pointer) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) do
        with unquote_splicing(prongs) do
          :ok
        end
      end

      unquote(accessories)
    end
  end

  defp accessory(call, key, schema, name, pointer, opts) do
    pointer = JsonPointer.join(pointer, key)
    inner_call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_map_key(content, unquote(key)) do
        unquote(inner_call)(content, path)
      end

      defp unquote(call)(content, path), do: :ok

      require Exonerate.Context
      Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
