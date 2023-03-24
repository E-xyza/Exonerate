defmodule Exonerate.Combining.Ref do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Remote
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
    |> build_filter(__CALLER__, authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(
         %{host: nil, path: nil, fragment: fragment},
         caller,
         authority,
         call_pointer,
         opts
       ) do
    ref_pointer = JsonPointer.from_uri(fragment)
    call = Tools.call(authority, call_pointer, opts)
    call_path = JsonPointer.to_path(call_pointer)
    opts = Keyword.delete(opts, :id)
    ref = Tools.call(authority, ref_pointer, opts)

    filter(call, ref, call_path, caller, authority, ref_pointer, opts)
  end

  defp build_filter(%{host: nil, path: path, fragment: fragment}, caller, authority, call_pointer, opts) do

    {path, fragment} |> dbg(limit: 25)
    raise "aaa"
    #ref_pointer =
    #  opts
    #  |> Keyword.fetch!(:id)
    #  |> URI.parse()
    #  |> Map.replace!(:path, "/" <> path)
    #  |> to_string()
    #  |> Cache.get_id(caller.module)
#
    #call = Tools.call(authority, call_pointer, opts)
    #ref = Tools.call(authority, ref_pointer, opts)
    #call_path = JsonPointer.to_path(call_pointer)
#
    #filter(call, ref, call_path, caller, authority, ref_pointer, opts)
  end

  defp build_filter(uri, caller, authority, call_pointer, opts) do
    call = Tools.call(authority, call_pointer, opts)
    ref_pointer = JsonPointer.from_uri(uri) # only takes the fragment

    authority = :"#{%{uri | fragment: nil}}"
    Remote.ensure_authority_loaded!(caller, authority, opts)
    ref = Tools.call(authority, ref_pointer, opts)
    call_path = JsonPointer.to_path(call_pointer)

    filter(call, ref, call_path, caller, authority, ref_pointer, opts)
  end

  defp filter(call, ref, call_path, caller, ref_authority, ref_pointer, opts) do
    caller
    |> Tools.subschema(ref_authority, ref_pointer)
    |> Degeneracy.class()
    |> case do
      :ok ->
        quote do
          @compile {:inline, [{unquote(call), 2}]}
          defp unquote(call)(_content, _path), do: :ok
        end

      :error ->
        # in this case we still need to regenerate the context because the degeneracy
        # failure is stored in the remote call.

        quote do
          @compile {:inline, [{unquote(call), 2}]}
          defp unquote(call)(content, path) do
            unquote(ref)(content, path)
          end

          require Exonerate.Context
          Exonerate.Context.filter(unquote(ref_authority), unquote(ref_pointer), unquote(opts))
        end

      :unknown ->
        quote do
          defp unquote(call)(content, path) do
            case unquote(ref)(content, path) do
              {:error, error} ->
                ref_trace = Keyword.get(error, :ref_trace, [])
                new_error = Keyword.put(error, :ref_trace, [unquote(call_path) | ref_trace])
                {:error, new_error}

              ok ->
                ok
            end
          end

          require Exonerate.Context
          Exonerate.Context.filter(unquote(ref_authority), unquote(ref_pointer), unquote(opts))
        end
    end
  end
end
