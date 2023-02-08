defmodule Exonerate.Filter.MinMaxLength do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    call = pointer
    |> JsonPointer.traverse("min-max-length")
    |> Tools.pointer_to_fun_name(authority: name)

    min_pointer = pointer
    |> JsonPointer.traverse("minLength")
    |> JsonPointer.to_uri

    max_pointer = pointer
    |> JsonPointer.traverse("maxLength")
    |> JsonPointer.to_uri

    schema = Cache.fetch!(name)

    max_length = JsonPointer.resolve!(schema, JsonPointer.traverse(pointer, "maxLength"))
    min_length = JsonPointer.resolve!(schema, JsonPointer.traverse(pointer, "minLength"))

    Tools.maybe_dump(quote do
      def unquote(call)(string, path) do
        case String.length(string) do
          length when length < unquote(min_length) ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(min_pointer), path)

          length when length > unquote(max_length) ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(string, unquote(max_pointer), path)

          _ ->

        end
      end
    end, opts)
  end
end
