defmodule Exonerate.Filter.MaxProperties do
  @moduledoc false
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(maximum, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(object, path) do
        case object do
          object when map_size(object) <= unquote(maximum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(object, unquote(resource), unquote(pointer), path)
        end
      end
    end
  end
end
