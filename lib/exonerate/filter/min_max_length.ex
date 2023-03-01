defmodule Exonerate.Filter.MinMaxLength do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    call =
      pointer
      |> JsonPointer.join("min-max-length")
      |> Tools.pointer_to_fun_name(authority: name)

    min_pointer =
      pointer
      |> JsonPointer.join("minLength")
      |> JsonPointer.to_uri()

    max_pointer =
      pointer
      |> JsonPointer.join("maxLength")
      |> JsonPointer.to_uri()

    schema = Cache.fetch!(__CALLER__.module, name)

    max_length = JsonPointer.resolve!(schema, JsonPointer.join(pointer, "maxLength"))
    min_length = JsonPointer.resolve!(schema, JsonPointer.join(pointer, "minLength"))

    format_binary =
      schema
      |> JsonPointer.resolve!(pointer)
      |> Map.get("format")
      |> Kernel.===("binary")

    call
    |> build_code(min_length, min_pointer, max_length, max_pointer, format_binary)
    |> Tools.maybe_dump(opts)
  end

  defp build_code(call, min_length, min_pointer, max_length, max_pointer, true) do
    quote do
      defp unquote(call)(string, path) when byte_size(string) < unquote(min_length) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(string, unquote(min_pointer), path)
      end

      defp unquote(call)(string, path) when byte_size(string) > unquote(max_length) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(string, unquote(max_pointer), path)
      end

      defp unquote(call)(string, path), do: :ok
    end
  end

  defp build_code(call, min_length, min_pointer, max_length, max_pointer, false) do
    quote do
      defp unquote(call)(string, path) do
        case String.length(string) do
          length when length < unquote(min_length) ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(min_pointer), path)

          length when length > unquote(max_length) ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(max_pointer), path)

          _ ->
            :ok
        end
      end
    end
  end
end
