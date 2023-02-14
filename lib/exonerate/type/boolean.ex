defmodule Exonerate.Type.Boolean do
  @moduledoc false

  alias Exonerate.Combining
  alias Exonerate.Tools

  @filters Combining.filters()

  def filter(schema, name, pointer) do
    filters =
      schema
      |> Map.take(@filters)
      |> Enum.map(&filter_for(&1, name, pointer))

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_boolean(content) do
        with unquote_splicing(filters) do
          :ok
        end
      end
    end
  end

  defp filter_for({filter, _}, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse(filter)
      |> Tools.pointer_to_fun_name(authority: name)

    quote do
      :ok <- unquote(call)(content, path)
    end
  end

  def accessories(_, _, _, _), do: []
end
