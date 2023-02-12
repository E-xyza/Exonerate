defmodule Exonerate.Type.Boolean do
  @moduledoc false

  alias Exonerate.Tools

  def filter(_schema, name, pointer) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_boolean(content) do
        :ok
      end
    end
  end

  def accessories(_, _, _, _), do: []
end
