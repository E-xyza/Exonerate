defmodule Exonerate.Filter.MaxLength do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(max, caller, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    case Tools.parent(caller, resource, pointer) do
      %{"format" => "binary"} ->
        quote do
          defp unquote(call)(string, path) when byte_size(string) > unquote(max) do
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(resource), unquote(pointer), path)
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
                Exonerate.Tools.mismatch(string, unquote(resource), unquote(pointer), path)
            end
          end
        end
    end
  end
end
