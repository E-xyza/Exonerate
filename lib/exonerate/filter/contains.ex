defmodule Exonerate.Filter.Contains do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter_from_cached(name, pointer, opts) do
    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
    |> Iterator.mode()
    |> case do
      :filter ->
        entrypoint_call =
          pointer
          |> JsonPointer.traverse(":entrypoint")
          |> Tools.pointer_to_fun_name(authority: name)

        call = Tools.pointer_to_fun_name(pointer, authority: name)

        quote do
          defp unquote(entrypoint_call)(content, path, contains) do
            case unquote(call)(content, path) do
              :ok -> contains + 1
              {:error, _} -> contains
            end
          end

          require Exonerate.Context
          Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
        end

      :find ->
        quote do
          require Exonerate.Context
          Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
        end
    end
    |> Tools.maybe_dump(opts)
  end
end
