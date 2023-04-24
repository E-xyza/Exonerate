defmodule Exonerate.Combining.Not do
  @moduledoc false

  alias Exonerate.Combining
  alias Exonerate.Tools
  alias Exonerate.Degeneracy

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Combining.dedupe(__CALLER__, resource, pointer, :entrypoint, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(context, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)
    entrypoint_call = Tools.call(resource, pointer, :entrypoint, opts)

    ###############################################################
    # this section for suppressing clause matching compiler warning

    switch =
      case Degeneracy.class(context) do
        :unknown ->
          quote do
            case unquote(call)(data, path) do
              :ok ->
                Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path)

              {:error, _} ->
                :ok
            end
          end

        :ok ->
          quote do
            Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path)
          end

        :error ->
          :ok
      end

    #############################################################

    quote do
      defp unquote(entrypoint_call)(data, path) do
        require Exonerate.Tools
        unquote(switch)
      end

      require Exonerate.Context
      Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
    end
  end
end
