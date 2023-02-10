defmodule Exonerate.Filter.Properties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  # TODO: figure out draft-4 stuff

  # TODO: figure out requireds
  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    {filters, properties} =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)
      |> Enum.map(&to_with_filter(&1, name, pointer, opts))
      |> Enum.unzip()

    Tools.maybe_dump(
      quote do
        defp unquote(call)(object, path) do
          with unquote_splicing(filters) do
            :ok
          end
        end

        unquote(properties)
      end,
      opts
    )
  end

  defp to_with_filter({key, _schema}, name, pointer, opts) do
    pointer = JsonPointer.traverse(pointer, key)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    {quote do
       :ok <-
         case Map.fetch(object, unquote(key)) do
           :error ->
             :ok

           {:ok, value} ->
             unquote(call)(value, Path.join(path, unquote(key)))
         end
     end,
     quote do
       require Exonerate.Context
       Exonerate.Context.from_cached(unquote(name), unquote(pointer), unquote(opts))
     end}
  end
end
