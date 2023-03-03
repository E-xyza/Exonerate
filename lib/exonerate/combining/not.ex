defmodule Exonerate.Combining.Not do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    # note this needs to change if we are doing unevaluateds, since we must
    # evaluate ALL options

    entrypoint_call =
      pointer
      |> JsonPointer.join(":entrypoint")
      |> Tools.pointer_to_fun_name(authority: name)

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    schema_pointer = JsonPointer.to_uri(pointer)

    Tools.maybe_dump(
      quote do
        defp unquote(entrypoint_call)(value, path) do
          require Exonerate.Tools

          case unquote(call)(value, path) do
            :ok ->
              Exonerate.Tools.mismatch(value, unquote(schema_pointer), path, matches: [value])

            {:error, _} ->
              :ok
          end
        end

        require Exonerate.Context
        Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
      end,
      opts
    )
  end
end
