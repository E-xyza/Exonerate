defmodule Exonerate.Type.String do
  @moduledoc false

  def type_filter(call, %{"format" => "binary"}) do
    quote do
      def unquote(call)(content, path) when is_binary(content) do
        :ok
      end
    end
  end

  def type_filter(call, _schema) do
    quote do
      def unquote(call)(content, path) when is_binary(content) do
        if String.valid?(content) do
          :ok
        else
          require Exonerate.Tools
          Exonerate.Tools.mismatch(content, path, guard: "type")
        end
      end
    end
  end
end
