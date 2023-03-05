defmodule Exonerate.Filter.PropertyNames do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(schema, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)
    special_opts = Keyword.put(opts, :only, ["string"])

    subfilter = quote do
      defp unquote(call)({k, _v}, path) do
        unquote(call)(k, path)
      end
    end

    context = quote do
      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(special_opts))
    end

    quote do
      unquote(subfilter)
      unquote(context)
    end
  end
end
