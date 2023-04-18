defmodule Exonerate.Filter.Items do
  @moduledoc false
  alias Exonerate.Tools

  # NOTE this generates an iterator function
  # !! important this generator gets called regardless of if the items property
  # is present in the subschema object

  defmacro filter(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  # items which is now "additionalItems"
  def build_filter(%{"items" => subschema}, resource, pointer, opts) when is_map(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    items_call = Tools.call(resource, JsonPointer.join(pointer, "items"), opts)

    quote do
      defp unquote(iterator_call)(array, [item | rest], index, path) do
        require Exonerate.Tools

        case unquote(items_call)(item, Path.join(path, "#{index}")) do
          :ok ->
            unquote(iterator_call)(array, rest, index + 1, path)

          Exonerate.Tools.error_match(error) ->
            error
        end
      end

      defp unquote(iterator_call)(_, [], index, path) do
        :ok
      end
    end
  end

  # the list form of items is technically supposed to be "prefixItems" but
  # it's supposed to be supported in newer versions of the spec.
  def build_filter(%{"items" => subschema}, resource, pointer, opts) when is_list(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)

    Enum.with_index(subschema, fn _, index ->
      items_call = Tools.call(resource, JsonPointer.join(pointer, ["items", "#{index}"]), opts)

      quote do
        defp unquote(iterator_call)(array, [item | rest], unquote(index), path) do
          require Exonerate.Tools

          case unquote(items_call)(item, Path.join(path, "#{unquote(index)}")) do
            :ok ->
              unquote(iterator_call)(array, rest, unquote(index + 1), path)

            Exonerate.Tools.error_match(error) ->
              error
          end
        end
      end
    end)
  end

  def build_filter(_, _resource, _pointer, _opts), do: []

  defmacro context(resource, pointer, opts) do
    # The pointer in this case is the pointer to the array context, because
    # this filter is an iterator function.

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_context(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_context(subschema, resource, pointer, opts) when is_map(subschema) do
    quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
    end
  end

  defp build_context(subschema, resource, pointer, opts) when is_list(subschema) do
    Enum.with_index(subschema, fn _, index ->
      pointer = JsonPointer.join(pointer, "#{index}")

      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end
    end)
  end
end
