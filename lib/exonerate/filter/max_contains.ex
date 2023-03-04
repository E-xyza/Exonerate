defmodule Exonerate.Filter.MaxContains do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> build_filter(name, pointer)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(maximum, name, pointer) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    quote do
      defp unquote(call)(content, parent, path) when content > unquote(maximum) do
        require Exonerate.Tools
        Tools.mismatch(parent, unquote(schema_pointer), path)
      end

      defp unquote(call)(_, _, _), do: :ok
    end
  end
end
