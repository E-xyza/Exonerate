defmodule Exonerate.Filter.Maximum do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff

  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> build_code(call, schema_pointer)
    |> Tools.maybe_dump(opts)
  end

  defp build_code(maximum, call, schema_pointer) do
    quote do
      defp unquote(call)(number, path) do
        case number do
          value when value <= unquote(maximum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(schema_pointer), path)
        end
      end
    end
  end
end
