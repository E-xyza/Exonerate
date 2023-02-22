defmodule Exonerate.Filter.MaxProperties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff

  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    maximum =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(pointer)

    Tools.maybe_dump(
      quote do
        defp unquote(call)(object, path) do
          case object do
            object when map_size(object) <= unquote(maximum) ->
              :ok

            _ ->
              require Exonerate.Tools
              Exonerate.Tools.mismatch(object, unquote(schema_pointer), path)
          end
        end
      end,
      opts
    )
  end
end
