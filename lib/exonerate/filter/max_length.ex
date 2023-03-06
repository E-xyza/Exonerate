defmodule Exonerate.Filter.MaxLength do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(__CALLER__, authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(max, caller, authority, pointer, opts) do
    call = Tools.call(authority, pointer, opts)

    case Tools.parent(caller, authority, pointer) do
      %{"format" => "binary"} ->
        quote do
          defp unquote(call)(string, path) when byte_size(string) > unquote(max) do
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(pointer), path)
          end

          defp unquote(call)(string, path), do: :ok
        end

      _ ->
        quote do
          defp unquote(call)(string, path) do
            case String.length(string) do
              length when length <= unquote(max) ->
                :ok

              _ ->
                require Exonerate.Tools
                Exonerate.Tools.mismatch(string, unquote(pointer), path)
            end
          end
        end
    end
  end
end
