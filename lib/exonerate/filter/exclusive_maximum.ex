defmodule Exonerate.Filter.ExclusiveMaximum do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(pointer)
    |> case do
      bool when is_boolean(bool) ->
        # TODO: figure out a draft-4 warning here
        filter_boolean(bool, call, fetch_maximum!(name, pointer), schema_pointer)

      value ->
        filter_value(value, call, schema_pointer)
    end
    |> Tools.maybe_dump(opts)
  end

  defp fetch_maximum!(name, pointer) do
    maximum_pointer =
      pointer
      |> JsonPointer.backtrack!()
      |> JsonPointer.traverse("maximum")

    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(maximum_pointer)
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
          value when value < unquote(maximum) ->
            :ok

          _ ->
            require Exonerate.Tools
            Exonerate.Tools.mismatch(number, unquote(schema_pointer), path)
        end
      end
    end
  end
end
