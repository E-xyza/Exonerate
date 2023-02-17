defmodule Exonerate.Type.Object do
  @moduledoc false

  alias Exonerate.Tools
  alias Exonerate.Type.Object.Iterator
  alias Exonerate.Combining

  @modules %{
    "minProperties" => Exonerate.Filter.MinProperties,
    "maxProperties" => Exonerate.Filter.MaxProperties,
    "required" => Exonerate.Filter.Required,
    "dependencies" => Exonerate.Filter.Dependencies
  }

  @filters Map.keys(@modules)

  # additionalProperties clobbers unevaluatedProperties
  def filter(
        subschema = %{"additionalProperties" => _, "unevaluatedProperties" => _},
        name,
        pointer
      ) do
    subschema
    |> Map.delete("unevaluatedProperties")
    |> filter(name, pointer)
  end

  def filter(subschema, name, pointer) do
    outer_filters = outer_filters(subschema, name, pointer)
    iterator_filter = iterator_filter(subschema, name, pointer)

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_map(content) do
        with unquote_splicing(outer_filters ++ iterator_filter) do
          :ok
        end
      end
    end
  end

  defp outer_filters(subschema, name, pointer) do
    for filter <- @filters, is_map_key(subschema, filter) do
      call =
        pointer
        |> JsonPointer.traverse(filter)
        |> Tools.pointer_to_fun_name(authority: name)

      quote do
        :ok <- unquote(call)(content, path)
      end
    end
  end

  defp iterator_filter(subschema, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse(":iterator")
      |> Tools.pointer_to_fun_name(authority: name)

    List.wrap(
      if Iterator.needs_iterator?(subschema) do
        quote do
          :ok <- unquote(call)(content, path)
        end
      end
    )
  end

  def accessories(subschema, name, pointer, opts) do
    List.wrap(
      if Iterator.needs_iterator?(subschema) do
        quote do
          require Exonerate.Type.Object.Iterator

          Exonerate.Type.Object.Iterator.from_cached(
            unquote(name),
            unquote(pointer),
            unquote(opts)
          )
        end
      end
    ) ++
      for filter <- @filters, is_map_key(subschema, filter) do
        module = @modules[filter]
        pointer = JsonPointer.traverse(pointer, filter)

        quote do
          require unquote(module)
          unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
        end
      end
  end
end
