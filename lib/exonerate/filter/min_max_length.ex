defmodule Exonerate.Filter.MinMaxLength do
  @moduledoc false

  # this module merges minlength and maxlength checking,
  # so that the system doesn't have to do multiple passes across
  # the list to validate minlength and maxlength.

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    binary_mode =
      __CALLER__
      |> Tools.parent(resource, pointer)
      |> Map.get("format")
      |> Kernel.===("binary")

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, binary_mode, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter([min, max], resource, pointer, true, opts) do
    call = Tools.call(resource, pointer, opts)
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

      defp unquote(call)(_string, _path), do: :ok
    end
  end

  defp build_filter([min, max], resource, pointer, false, opts) do
    call = Tools.call(resource, pointer, opts)
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
