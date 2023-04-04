defmodule Exonerate.Filter.DependentSchemas do
  @moduledoc false

  # NB "dependentSchemas" is just a repackaging of "dependencies" except only permitting the
  # maps (specification of a full subschema to be applied to the object)

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> Enum.map(&prong_and_accessory(&1, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp prong_and_accessory({key, _schema}, resource, pointer, opts) do
    call = Tools.call(resource, JsonPointer.join(pointer, key), :entrypoint, opts)

    prong =
      if opts[:tracked] do
        quote do
          [{:ok, new_seen} <- unquote(call)(content, path), seen = MapSet.union(seen, new_seen)]
        end
      else
        quote do
          [:ok <- unquote(call)(content, path)]
        end
      end

    accessory = accessory(call, key, resource, pointer, opts)

    {prong, accessory}
  end

  defp accessory(call, key, resource, pointer, opts) do
    context_opts = Tools.scrub(opts)
    pointer = JsonPointer.join(pointer, key)
    context_call = Tools.call(resource, pointer, context_opts)

    fallthrough =
      if opts[:tracked] do
        quote do
          {:ok, MapSet.new()}
        end
      else
        :ok
      end

    quote do
      defp unquote(call)(content, path) when is_map_key(content, unquote(key)) do
        unquote(context_call)(content, path)
      end

      defp unquote(call)(content, path), do: unquote(fallthrough)

      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(context_opts))
    end
  end

  defp build_filter({prongs, accessories}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    prongs = Enum.flat_map(prongs, &Function.identity/1)

    if opts[:tracked] do
      build_tracked(call, prongs, accessories)
    else
      build_untracked(call, prongs, accessories)
    end
  end

  defp build_tracked(call, prongs, accessories) do
    quote do
      defp unquote(call)(content, path) do
        seen = MapSet.new()

        with unquote_splicing(prongs) do
          {:ok, seen}
        end
      end

      unquote(accessories)
    end
  end

  defp build_untracked(call, prongs, accessories) do
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
