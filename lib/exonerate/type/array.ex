defmodule Exonerate.Type.Array do
  @moduledoc false

  @behaviour Exonerate.Type

  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  @modules Iterator.filter_modules()
  @iterator_filters Iterator.filters()

  @module_keys Combining.filters()

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  def build_filter(context, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    iterator_filters =
      List.wrap(
        if Iterator.mode(context) do
          iterator_call = Tools.call(authority, JsonPointer.join(pointer, ":iterator"), opts)

          quote do
            :ok <- unquote(iterator_call)(array, path)
          end
        end
      )

    quote do
      defp unquote(call)(array, path) when is_list(array) do
        with unquote_splicing(iterator_filters) do
          :ok
        end
      end
    end
  end

  defp filter_for({filter, _}, name, pointer) do
    call =
      pointer
      |> JsonPointer.join(Combining.adjust(filter))
      |> Tools.pointer_to_fun_name(authority: name)

    quote do
      :ok <- unquote(call)(content, path)
    end
  end

  defmacro accessories(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_accessories(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_accessories(context, authority, pointer, opts) do
    List.wrap(
      if Iterator.mode(context) do
        quote do
          require Exonerate.Type.Array.Iterator

          Exonerate.Type.Array.Iterator.filter(
            unquote(authority),
            unquote(pointer),
            unquote(opts)
          )

          Exonerate.Type.Array.Iterator.accessories(
            unquote(authority),
            unquote(pointer),
            unquote(opts)
          )
        end
      end
    )
  end
end
