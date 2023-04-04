defmodule Exonerate.Filter.Required do
  @moduledoc false

  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(opts)
  end

  defp build_filter(required_list, resource, pointer, opts) do
    quote do
      defp unquote(Tools.call(resource, pointer, opts))(object, path) do
        unquote(required_list)
        |> Enum.reduce_while({:ok, 0}, fn
          required_field, {:ok, index} when is_map_key(object, required_field) ->
            {:cont, {:ok, index + 1}}

          required_field, {:ok, index} ->
            require Exonerate.Tools

            {:halt,
             {Exonerate.Tools.mismatch(
                object,
                unquote(resource),
                {unquote(pointer), "#{index}"},
                path,
                required: Path.join(path, required_field)
              ), []}}
        end)
        |> elem(0)
      end
    end
  end
end
