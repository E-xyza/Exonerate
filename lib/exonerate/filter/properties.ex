defmodule Exonerate.Filter.Properties do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(subschema, authority, pointer, opts) do
    main_call = Tools.call(authority, pointer, opts)

    {subfilters, contexts} =
      subschema
      |> Enum.map(&filters_for(&1, main_call, authority, pointer, Keyword.delete(opts, :tracked)))
      |> Enum.unzip()

    negative =
      if opts[:tracked] do
        {:ok, false}
      else
        :ok
      end

    quote do
      unquote(subfilters)
      defp unquote(main_call)(_, _), do: unquote(negative)
      unquote(contexts)
    end
  end

  defp filters_for({key, _schema}, main_call, authority, pointer, opts) do
    key_pointer = JsonPointer.join(pointer, key)
    key_call = Tools.call(authority, key_pointer, opts)

    subfilter =
      if opts[:tracked] do
        quote do
          defp unquote(main_call)({unquote(key), value}, path) do
            case unquote(key_call)(value, Path.join(path, unquote(key))) do
              :ok -> {:ok, true}
              error -> error
            end
          end
        end
      else
        quote do
          defp unquote(main_call)({unquote(key), value}, path) do
            unquote(key_call)(value, Path.join(path, unquote(key)))
          end
        end
      end

    context =
      quote do
        require Exonerate.Context

        Exonerate.Context.filter(
          unquote(authority),
          unquote(key_pointer),
          unquote(Keyword.delete(opts, :tracked))
        )
      end

    {subfilter, context}
  end
end
