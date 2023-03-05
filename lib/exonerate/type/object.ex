defmodule Exonerate.Type.Object do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Tools
  alias Exonerate.Combining
  alias Exonerate.Type.Object.Iterator

  @modules %{
    "minProperties" => Exonerate.Filter.MinProperties,
    "maxProperties" => Exonerate.Filter.MaxProperties,
    "required" => Exonerate.Filter.Required,
    "dependencies" => Exonerate.Filter.Dependencies,
    "dependentRequired" => Exonerate.Filter.DependentRequired,
    "dependentSchemas" => Exonerate.Filter.DependentSchemas
  }

  @outer_filters Map.keys(@modules)

  @combining_filters Combining.filters()

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, authority, pointer, opts) do
    filter_clauses =
      for filter <- @outer_filters, is_map_key(context, filter) do
        filter_call = Tools.call(authority, JsonPointer.join(pointer, filter), opts)

        quote do
          :ok <- unquote(filter_call)(object, path)
        end
      end ++
        List.wrap(
          if Iterator.needed?(context) do
            iterator_call = Tools.call(authority, JsonPointer.join(pointer, ":iterator"), opts)

            quote do
              :ok <- unquote(iterator_call)(object, path)
            end
          end
        )

    quote do
      defp unquote(Tools.call(authority, pointer, opts))(object, path) when is_map(object) do
        with unquote_splicing(filter_clauses) do
          :ok
        end
      end
    end
  end

  defmacro accessories(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_accessories(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, name, pointer, opts) do
    for filter <- @outer_filters, is_map_key(context, filter), not Combining.filter?(filter) do
      module = @modules[filter]
      pointer = JsonPointer.join(pointer, filter)

      quote do
        require unquote(module)
        unquote(module).filter(unquote(name), unquote(pointer), unquote(opts))
      end
    end ++
      List.wrap(
        if Iterator.needed?(context) do
          quote do
            require Exonerate.Type.Object.Iterator
            Exonerate.Type.Object.Iterator.filter(unquote(name), unquote(pointer), unquote(opts))

            Exonerate.Type.Object.Iterator.accessories(
              unquote(name),
              unquote(pointer),
              unquote(opts)
            )
          end
        end
      )
  end
end
