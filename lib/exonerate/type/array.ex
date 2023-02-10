defmodule Exonerate.Type.Array do
  alias Exonerate.Tools

  @modules %{
    "items" => Exonerate.Filter.Items
  }

  @filters Map.keys(@modules)

  # TODO: consider making a version where we don't bother indexing, if it's not necessary.

  def filter(_schema = %{"items" => items}, name, pointer) when is_list(items) do
    # TODO: rewrite this as prefix Items, conditionally on the version of the schema.
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_list(content) do
        :ok
      end
    end
  end

  def filter(schema, name, pointer) do
    filters =
      schema
      |> JsonPointer.resolve!(pointer)
      |> filter_calls(name, pointer)

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_list(content) do
        content
        |> Enum.reduce_while({:ok, 0}, fn
          item, {:ok, index} ->
            with unquote_splicing(filters) do
              {:cont, {:ok, index + 1}}
            else
              error -> {:halt, {error, []}}
            end
        end)
        |> elem(0)
      end
    end
  end

  defp filter_calls(schema, name, pointer) do
    case Map.take(schema, @filters) do
      empty when empty === %{} ->
        []

      filters ->
        build_filters(filters, name, pointer)
    end
  end

  defp build_filters(filters, name, pointer) do
    Enum.map(filters, &filter_for(&1, name, pointer))
  end

  defp filter_for({"items", _}, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse("items")
      |> Tools.pointer_to_fun_name(authority: name)

    quote do
      :ok <- unquote(call)(item, Path.join(path, "#{index}"))
    end
  end

  def accessories(schema, name, pointer, opts) do
    for filter_name <- @filters, Map.has_key?(schema, filter_name) do
      list_accessory(filter_name, schema, name, pointer, opts)
    end
  end

  defp list_accessory(filter_name, _schema, name, pointer, opts) do
    module = @modules[filter_name]
    pointer = JsonPointer.traverse(pointer, filter_name)

    quote do
      require unquote(module)
      unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
