defmodule Exonerate.Type.Ref do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    call_path = JsonPointer.to_uri(pointer)

    ref = name
    |> Cache.fetch!
    |> JsonPointer.resolve!(JsonPointer.traverse(pointer, "$ref"))
    |> normalize
    |> JsonPointer.from_uri
    |> Tools.pointer_to_fun_name(authority: name)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        case unquote(ref)(content, path) do
          :ok -> :ok
          {:error, error} ->
            ref_trace = Keyword.get(error, :ref_trace, [])
            new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
            {:error, new_error}
        end
      end
    end
  end

  defp normalize("#" <> string), do: normalize(string)
  defp normalize(""), do: "/"
  defp normalize(string), do: string
end
