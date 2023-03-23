defmodule Exonerate.Combining.Not do
  @moduledoc false
  alias Exonerate.Tools
  alias Exonerate.Degeneracy

  defmacro filter(authority, pointer, opts) do
    __CALLER__
    |> build_filter(authority, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(caller, authority, pointer, opts) do
    subschema = Tools.subschema(caller, authority, pointer)
    call = Tools.call(authority, pointer, opts)
    entrypoint_call = Tools.call(authority, JsonPointer.join(pointer, ":entrypoint"), opts)

    ###############################################################
    # this section for suppressing clause matching compiler warning

    switch =
      case Degeneracy.class(subschema) do
        :unknown ->
          quote do
            case unquote(call)(value, path) do
              :ok ->
                Exonerate.Tools.mismatch(value, unquote(pointer), path)

              {:error, _} ->
                :ok
            end
          end

        :ok ->
          quote do
            Exonerate.Tools.mismatch(value, unquote(pointer), path)
          end

        :error ->
          :ok
      end

    #############################################################

    quote do
      defp unquote(entrypoint_call)(value, path) do
        require Exonerate.Tools
        unquote(switch)
      end

      require Exonerate.Context
      Exonerate.Context.filter(unquote(authority), unquote(pointer), unquote(opts))
    end
  end
end
