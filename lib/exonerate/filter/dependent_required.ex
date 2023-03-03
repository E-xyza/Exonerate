defmodule Exonerate.Filter.DependentRequired do
  # note that dependentRequired is a repackaging of the legacy "dependencies" but only
  # permitting the array form, which is deprecated in later drafts of JsonSchema

  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> Enum.map(&make_dependencies(&1, name, pointer, opts))
    |> Enum.unzip()
    |> build_code(name, pointer)
    |> Tools.maybe_dump(opts)
  end

  defp make_dependencies({key, schema}, name, pointer, opts) do
    call =
      pointer
      |> JsonPointer.join([key, ":entrypoint"])
      |> Tools.pointer_to_fun_name(authority: name)

    {quote do
       :ok <- unquote(call)(content, path)
     end, accessory(call, key, schema, name, pointer, opts)}
  end

  defp build_code({prongs, accessories}, name, pointer) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) do
        with unquote_splicing(prongs) do
          :ok
        end
      end

      unquote(accessories)
    end
  end

  defp accessory(call, key, schema, _name, pointer, _opts) when is_list(schema) do
    prongs =
      Enum.with_index(schema, fn
        dependent_key, index ->
          schema_pointer =
            pointer
            |> JsonPointer.join([key, "#{index}"])
            |> JsonPointer.to_uri()

          quote do
            :ok <-
              if is_map_key(content, unquote(dependent_key)) do
                :ok
              else
                require Exonerate.Tools
                Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
              end
          end
      end)

    quote do
      defp unquote(call)(content, path) when is_map_key(content, unquote(key)) do
        with unquote_splicing(prongs) do
          :ok
        end
      end

      defp unquote(call)(content, path), do: :ok
    end
  end
end
