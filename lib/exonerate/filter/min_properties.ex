defmodule Exonerate.Filter.MinProperties do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(minimum, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(object, path) do
        case object do
          object when map_size(object) >= unquote(minimum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(object, unquote(pointer), path)
        end
      end
    end
  end
end
