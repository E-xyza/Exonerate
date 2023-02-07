defmodule Exonerate.Type.Number do
  @moduledoc false

  def type_filter(call, _schema) do
    quote do
      def unquote(call)(content, path) when is_number(content) do
        :ok
      end
    end
  end
end
