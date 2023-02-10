defmodule Exonerate.Filter.Required do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    required_list =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)

    Tools.maybe_dump(
      quote do
        def unquote(call)(object, path) do
          unquote(required_list)
          |> Enum.reduce_while({:ok, 0}, fn
            required_field, {:ok, index} when is_map_key(object, required_field) ->
              {:cont, {:ok, index + 1}}

            required_field, {:ok, index} ->
              require Exonerate.Tools

              {:halt,
               {Exonerate.Tools.mismatch(
                  object,
                  Path.join(unquote(schema_pointer), "#{index}"),
                  path
                ), :discard}}
          end)
          |> elem(0)
        end
      end,
      opts
    )
  end
end
