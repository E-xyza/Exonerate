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
  def build_filter(%{"items" => subschema}, resource, pointer, opts) when is_list(subschema) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    items_call = Tools.call(resource, JsonPointer.join(pointer, "items") , opts)

    quote do
      defp unquote(iterator_call)(array, [item | rest], index, path) do
        case unquote(items_call)(item, Path.join(path, "#{index}")) do
          :ok ->
            unquote(iterator_call)(array, rest, index + 1, path)

          error = {:error, _} ->
            error
        end
      end

      defp unquote(iterator_call)(_, [], index, path) do
        :ok
      end
    end
  end

  def build_filter(_, resource, pointer, opts) do
    iterator_call = Tools.call(resource, pointer, :array_iterator, opts)
    quote do
      defp unquote(iterator_call)(array, [_item | rest], index, path) do
        unquote(iterator_call)(array, rest, index + 1, path)
      end

      defp unquote(iterator_call)(_, [], index, path) do
        :ok
      end
    end
  end
end
