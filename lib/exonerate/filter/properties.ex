defmodule Exonerate.Filter.Properties do
  @moduledoc false

  alias Exonerate.Context
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(subschema, resource, pointer, opts) do
    main_call = Tools.call(resource, pointer, opts)

    {subfilters, contexts} =
      subschema
      |> Enum.map(&filters_for(&1, main_call, resource, pointer, opts))
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

  defp filters_for({key, _schema}, main_call, resource, pointer, opts) do
    context_opts = Context.scrub_opts(opts)
    context_pointer = JsonPtr.join(pointer, key)
    context_call = Tools.call(resource, context_pointer, context_opts)

    subfilter =
      if opts[:tracked] do
        quote do
          defp unquote(main_call)({unquote(key), value}, path) do
            require Exonerate.Tools

            case unquote(context_call)(value, Path.join(path, unquote(key))) do
              :ok -> {:ok, true}
              Exonerate.Tools.error_match(error) -> error
            end
          end
        end
      else
        quote do
          defp unquote(main_call)({unquote(key), value}, path) do
            unquote(context_call)(value, Path.join(path, unquote(key)))
          end
        end
      end

    context =
      quote do
        require Exonerate.Context

        Exonerate.Context.filter(
          unquote(resource),
          unquote(context_pointer),
          unquote(context_opts)
        )
      end

    {subfilter, context}
  end
end
