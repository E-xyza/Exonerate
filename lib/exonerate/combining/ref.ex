defmodule Exonerate.Combining.Ref do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Id
  alias Exonerate.Remote
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    # a ref might be:

    # - reference to something local (usually starts with #)
    # - reference to something set with an id
    # - remote reference.

    # condition the options to accept unevaluatedProperties

    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> URI.parse()
    |> build_filter(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(
         %{scheme: nil, userinfo: nil, host: nil, path: nil, query: nil, fragment: fragment},
         caller,
         resource,
         call_pointer,
         opts
       ) do
    ref_pointer = JsonPointer.from_uri(fragment)
    call = Tools.call(resource, call_pointer, opts)
    call_path = {resource, JsonPointer.to_path(call_pointer)}
    opts = Keyword.delete(opts, :id)
    ref = Tools.call(resource, ref_pointer, opts)

    filter(call, ref, call_path, caller, resource, ref_pointer, opts)
  end

  defp build_filter(
         %{
           scheme: nil,
           userinfo: nil,
           host: nil,
           port: nil,
           path: path,
           query: query,
           fragment: fragment
         },
         caller,
         resource,
         call_pointer,
         opts
       ) do
    base_uri = resource |> to_string |> URI.parse()

    call_resource =
      %{base_uri | path: absolute(path), query: query}
      |> to_string
      |> String.to_atom()

    ref_pointer = JsonPointer.from_path(fragment)

    call = Tools.call(resource, call_pointer, opts)
    call_path = {resource, call_pointer}

    ref = Tools.call(call_resource, ref_pointer, opts)

    filter(call, ref, call_path, caller, call_resource, ref_pointer, opts)
  end

  defp build_filter(uri, caller, resource, call_pointer, opts) do
    call = Tools.call(resource, call_pointer, opts)
    # only takes the fragment
    ref_pointer = JsonPointer.from_uri(uri)
    resource = Tools.uri_to_resource(uri)

    ref = Tools.call(resource, ref_pointer, opts)
    call_path = {resource, JsonPointer.to_path(call_pointer)}

    filter(call, ref, call_path, caller, resource, ref_pointer, opts)
  end

  defp filter(call, ref, call_path, caller, ref_resource, ref_pointer, opts) do
    caller
    |> Tools.subschema(ref_resource, ref_pointer)
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
          Exonerate.Context.filter(unquote(ref_resource), unquote(ref_pointer), unquote(opts))
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
          Exonerate.Context.filter(unquote(ref_resource), unquote(ref_pointer), unquote(opts))
        end
    end
  end

  defp absolute(path = "/" <> _), do: path
  defp absolute(path), do: "/" <> path
end
