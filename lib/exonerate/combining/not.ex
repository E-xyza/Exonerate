defmodule Exonerate.Combining.Not do
  @moduledoc false
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    authority
    |> build_filter(pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)
    entrypoint_call = Tools.call(authority, JsonPointer.join(pointer, ":entrypoint"), opts)

    quote do
      defp unquote(entrypoint_call)(value, path) do
        require Exonerate.Tools

        case unquote(call)(value, path) do
          :ok ->
            Exonerate.Tools.mismatch(value, unquote(pointer), path)

          {:error, _} ->
            :ok
        end
      end

      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
    end
  end
end
