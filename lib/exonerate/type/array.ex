defmodule Exonerate.Type.Array do
  alias Exonerate.Combining
  alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  @modules Iterator.filter_modules()
  @iterator_filters Iterator.filters()

  @module_keys Combining.filters()

  defp combining_filters(opts) do
    if Draft.before?(Keyword.get(opts, :draft, "2020-12"), "2019-09") do
      @module_keys -- ["$ref"]
    else
      @module_keys
    end
  end

  def filter(subschema, name, pointer, opts) do
    subschema = adjust(subschema)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    combining_filters =
      subschema
      |> Map.take(combining_filters(opts))
      |> Enum.map(&filter_for(&1, name, pointer))

    iterator_filter =
      List.wrap(
        if Iterator.mode(subschema) do
          iterator_call =
            pointer
            |> JsonPointer.join(":iterator")
            |> Tools.pointer_to_fun_name(authority: name)

          quote do
            :ok <- unquote(iterator_call)(content, path)
          end
        end
      )

    quote do
      defp unquote(call)(content, path) when is_list(content) do
        with unquote_splicing(combining_filters ++ iterator_filter) do
          :ok
        end
      end
    end
  end

  defp adjust(subschema = %{"minContains" => 0}) do
    subschema
    |> Map.drop(["minContains", "contains"])
    |> adjust
  end

  defp adjust(subschema), do: subschema

  defp filter_for({filter, _}, name, pointer) do
    call =
      pointer
      |> JsonPointer.join(Combining.adjust(filter))
      |> Tools.pointer_to_fun_name(authority: name)

    quote do
      :ok <- unquote(call)(content, path)
    end
  end

  def accessories(schema, name, pointer, opts) do
    schema
    |> adjust
    |> Iterator.accessories(name, pointer, opts)
    |> Kernel.++(
      for filter_name <- @iterator_filters, Map.has_key?(schema, filter_name) do
        list_accessory(filter_name, schema, name, pointer, opts)
      end
    )
  end

  defp list_accessory(filter_name, _schema, name, pointer, opts) do
    module = @modules[filter_name]
    pointer = JsonPointer.join(pointer, filter_name)

    quote do
      require unquote(module)
      unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
