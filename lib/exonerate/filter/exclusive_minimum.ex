defmodule Exonerate.Filter.ExclusiveMinimum do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff
  defmacro filter(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)
    module = __CALLER__.module

    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> case do
      bool when is_boolean(bool) ->
        # TODO: figure out a draft-4 warning here
        filter_boolean(bool, call, fetch_minimum!(module, name, pointer), schema_pointer)

      value ->
        filter_value(value, call, schema_pointer)
    end
    |> Tools.maybe_dump(opts)
  end

  defp fetch_minimum!(module, name, pointer) do
    minimum_pointer =
      pointer
      |> JsonPointer.backtrack!()
      |> JsonPointer.join("minimum")

    module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(minimum_pointer)
  end

  defp filter_boolean(false, call, _, _schema_pointer) do
    quote do
      @compile {:inline, [{unquote(call), 2}]}
      defp unquote(call)(_number, _path), do: :ok
    end
  end

  defp filter_boolean(true, call, maximum, schema_pointer) do
    quote do
      defp unquote(call)(number = unquote(maximum), path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(number, unquote(schema_pointer), path)
      end

      defp unquote(call)(_, _), do: :ok
    end
  end

  defp filter_value(maximum, call, schema_pointer) do
    quote do
      defp unquote(call)(number, path) do
        case number do
          value when value > unquote(maximum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(schema_pointer), path)
        end
      end
    end
  end
end
