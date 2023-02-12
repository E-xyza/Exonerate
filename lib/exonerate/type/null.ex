defmodule Exonerate.Type.Null do
  @moduledoc false


  alias Exonerate.Tools

  def filter(_schema, name, pointer) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_nil(content) do
        :ok
      end
    end
  end

  def accessories(_, _, _, _), do: []
end
