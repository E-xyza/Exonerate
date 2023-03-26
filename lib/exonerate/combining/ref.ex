defmodule Exonerate.Combining.Ref do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Degeneracy
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    # a ref might be:

    # - reference to something local (usually starts with #)
    # - reference to something set with an id
    # - remote reference.

    # condition the options to accept unevaluatedProperties
    {parent_pointer, "$ref"} = JsonPointer.pop(pointer)
    {ref_resource_uri, ref_pointer} = Cache.traverse_ref!(__CALLER__.module, resource, parent_pointer)
    ref_resource = :"#{ref_resource_uri}"

    __CALLER__
    |> Tools.subschema(ref_resource, ref_pointer)
    |> build_filter(resource, pointer, ref_resource, ref_pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(context, resource, pointer, ref_resource, ref_pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    call_path = {resource, JsonPointer.to_path(pointer)}

    ref_call = Tools.call(ref_resource, ref_pointer, opts)

    context
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
            unquote(ref_call)(content, path)
          end

          require Exonerate.Context
          Exonerate.Context.filter(unquote(ref_resource), unquote(ref_pointer), unquote(opts))
        end

      :unknown ->
        quote do
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
          Exonerate.Context.filter(unquote(ref_resource), unquote(ref_pointer), unquote(opts))
        end
    end
  end
end
