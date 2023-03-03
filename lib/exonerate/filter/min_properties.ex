defmodule Exonerate.Filter.MinProperties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff

  defmacro filter(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    minimum =
      __CALLER__.module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(pointer)

    Tools.maybe_dump(
      quote do
        defp unquote(call)(object, path) do
          case object do
            object when map_size(object) >= unquote(minimum) ->
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
