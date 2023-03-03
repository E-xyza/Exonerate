defmodule Exonerate.Filter.Contains do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Tools
  alias Exonerate.Type.Array.Iterator

  defmacro filter(name, pointer, opts) do
    module = __CALLER__.module

    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(JsonPointer.backtrack!(pointer))
    |> Iterator.mode()
    |> case do
      :filter ->
        filter(module, name, pointer, opts)

      :find ->
        quote do
          require Exonerate.Context
          Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
        end
    end
    |> Tools.maybe_dump(opts)
  end

  defp filter(module, name, pointer, opts) do
    entrypoint_call =
      pointer
      |> JsonPointer.join(":entrypoint")
      |> Tools.pointer_to_fun_name(authority: name)

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    schema_target =
      module
      |> Cache.fetch!(name)
      |> JsonPointer.resolve!(pointer)
      |> Degeneracy.class()
      |> case do
        :ok ->
          quote do
            defp unquote(entrypoint_call)(content, path, contains) do
              contains + 1
            end
          end

        :error ->
          quote do
            defp unquote(entrypoint_call)(content, path, contains) do
              contains
            end
          end

        :unknown ->
          quote do
            defp unquote(entrypoint_call)(content, path, contains) do
              case unquote(call)(content, path) do
                :ok -> contains + 1
                {:error, _} -> contains
              end
            end

            require Exonerate.Context
            Exonerate.Context.filter(unquote(name), unquote(pointer), unquote(opts))
          end
      end
  end
end
