defmodule Exonerate.Type.Array do
  alias Exonerate.Tools

  def filter(schema, name, pointer) do
    schema = JsonPointer.resolve!(schema, pointer)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      def unquote(call)(content, path) when is_list(content) do
        :ok
      end
    end
  end

  def accessories(_, _, _, _), do: []
end
