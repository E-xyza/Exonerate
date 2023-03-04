defmodule Exonerate.Filter.MinMaxLength do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    binary_mode =
      __CALLER__
      |> Tools.parent(authority, pointer)
      |> Map.get("format")
      |> Kernel.===("binary")

    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> build_filter(authority, pointer, binary_mode, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter([min, max], authority, pointer, true, opts) do
    call = Tools.call(authority, pointer, opts)
    parent_pointer = JsonPointer.backtrack!(pointer)

    quote do
      defp unquote(call)(string, path) when byte_size(string) < unquote(min) do
        require Exonerate.Tools

        Exonerate.Tools.mismatch(
          string,
          unquote(JsonPointer.join(parent_pointer, "minLength")),
          path
        )
      end

      defp unquote(call)(string, path) when byte_size(string) > unquote(max) do
        require Exonerate.Tools

        Exonerate.Tools.mismatch(
          string,
          unquote(JsonPointer.join(parent_pointer, "maxLength")),
          path
        )
      end

      defp unquote(call)(string, path), do: :ok
    end
  end

  defp build_filter([min, max], authority, pointer, false, opts) do
    call = Tools.call(authority, pointer, opts)
    parent_pointer = JsonPointer.backtrack!(pointer)

    quote do
      defp unquote(call)(string, path) do
        case String.length(string) do
          length when length < unquote(min) ->
            require Exonerate.Tools

            Exonerate.Tools.mismatch(
              string,
              unquote(JsonPointer.join(parent_pointer, "minLength")),
              path
            )

          length when length > unquote(max) ->
            require Exonerate.Tools

            Exonerate.Tools.mismatch(
              string,
              unquote(JsonPointer.join(parent_pointer, "maxLength")),
              path
            )

          _ ->
            :ok
        end
      end
    end
  end
end
