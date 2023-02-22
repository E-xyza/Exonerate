defmodule Exonerate.Id do
  alias Exonerate.Cache

  def prescan(schema, module) do
    prescan(schema, module, JsonPointer.from_uri("/"))
    schema
  end

  defp prescan(object = %{"id" => id}, module, pointer) do
    Cache.register_id(id, module, pointer)

    object
    |> Map.delete("id")
    |> prescan(module, pointer)
  end

  defp prescan(object, module, pointer) when is_map(object) do
    Enum.each(object, fn {k, v} ->
      prescan(v, module, JsonPointer.traverse(pointer, k))
    end)
  end

  defp prescan(array, module, pointer) when is_list(array) do
    array
    |> Enum.with_index()
    |> Enum.each(fn {v, idx} ->
      prescan(v, module, JsonPointer.traverse(pointer, "#{idx}"))
    end)
  end

  defp prescan(_, _, _), do: :ok
end
