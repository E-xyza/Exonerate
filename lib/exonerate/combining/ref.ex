defmodule Exonerate.Combining.Ref do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(authority, pointer, opts) do
    # a ref might be:

    # - reference to something local (usually starts with #)
    # - reference to something set with an id
    # - remote reference.

    # condition the options to accept unevaluatedProperties

    __CALLER__
    |> Tools.subschema(authority, pointer)
    |> URI.parse()
    |> build_filter(__CALLER__.module, authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp normalize(fragment = "/" <> _), do: fragment
  defp normalize(fragment), do: "/" <> fragment

  defp build_filter(
         %{host: nil, path: nil, fragment: fragment},
         _module,
         authority,
         call_pointer,
         opts
       ) do
    ref_pointer = JsonPointer.from_uri(fragment)

    call = Tools.call(authority, call_pointer, opts)

    call_path = JsonPointer.to_path(call_pointer)

    opts = Keyword.delete(opts, :id)

    ref_call = Tools.call(authority, ref_pointer, opts)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        case unquote(ref_call)(content, path) do
          {:error, error} ->
            ref_trace = Keyword.get(error, :ref_trace, [])
            new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
            {:error, new_error}

          ok ->
            ok
        end
      end

      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(ref_pointer), unquote(opts))
    end
  end

  defp build_filter(%{host: nil, path: path}, module, authority, call_pointer, opts) do
    ref_pointer =
      opts
      |> Keyword.fetch!(:id)
      |> URI.parse()
      |> Map.replace!(:path, "/" <> path)
      |> to_string()
      |> Cache.get_id(module)

    opts = Keyword.delete(opts, :id)

    call = Tools.call(authority, call_pointer, opts)
    ref = Tools.call(authority, ref_pointer, opts)
    call_path = JsonPointer.to_path(call_pointer)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(content, path) do
        case unquote(ref)(content, path) do
          :ok ->
            :ok

          {:error, error} ->
            ref_trace = Keyword.get(error, :ref_trace, [])
            new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
            {:error, new_error}
        end
      end

      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(ref_pointer), unquote(opts))
    end
  end
end
