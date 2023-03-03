defmodule Exonerate.Filter.MaxLength do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)
    schema = Cache.fetch!(__CALLER__.module, name)

    format_binary =
      schema
      |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
      |> Map.get("format")
      |> Kernel.===("binary")

    schema
    |> JsonPointer.resolve!(pointer)
    |> build_code(call, schema_pointer, format_binary)
    |> Tools.maybe_dump(opts)
  end

  defp build_code(length, call, schema_pointer, true) do
    quote do
      defp unquote(call)(string, path) when byte_size(string) > unquote(length) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(string, unquote(schema_pointer), path)
      end

      defp unquote(call)(string, path), do: :ok
    end
  end

  defp build_code(length, call, schema_pointer, false) do
    quote do
      defp unquote(call)(string, path) do
        case String.length(string) do
          length when length <= unquote(length) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(schema_pointer), path)
        end
      end
    end
  end
end
