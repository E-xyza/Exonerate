defmodule Exonerate.Filter.PropertyNames do
  @moduledoc false

  alias Exonerate.Context
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    resource
    |> build_filter(pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    # TODO: make sure we don't drop the only if this has been reffed.
    context_opts =
      opts
      |> Context.scrub_opts()
      |> Keyword.put(:only, ["string"])

    subfilter =
      quote do
        defp unquote(call)({key, _v}, path) do
          case unquote(call)(key, path) do
            :ok ->
              :ok

            {:error, errors} ->
              {:error, Keyword.update!(errors, :instance_location, &Path.join(&1, key))}
          end
        end
      end

    context =
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(context_opts))
      end

    quote do
      unquote(subfilter)
      unquote(context)
    end
  end
end
