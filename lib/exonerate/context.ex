defmodule Exonerate.Context do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    Tools.maybe_dump(
      case Cache.get(name) do
        {:ok, true} ->
          quote do
            @compile {:inline, [{unquote(call), 2}]}
            def unquote(call)(content, _path) do
              :ok
            end
          end

        {:ok, false} ->
          quote do
            @compile {:inline, [{unquote(call), 2}]}
            def unquote(call)(content, path) do
              require Exonerate.Tools
              Exonerate.Tools.mismatch(content, path)
            end
          end

        {:ok, schema} ->
          quote do
            unquote(type_filters(call, schema))
            # unquote(type_parsing(schema))
          end
      end,
      opts
    )
  end

  defp type_filters(call, %{"type" => "string"}) do
    quote do
      def unquote(call)(content, path) when is_binary(content) do
        if String.valid?(content) do
          :ok
        else
          require Exonerate.Tools
          Exonerate.Tools.mismatch(content, path, guard: "type")
        end
      end

      def unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, path, guard: "type")
      end
    end
  end

  defp type_filters(call, _) do
    quote do
      def unquote(call)(content, path) do
        :ok
      end
    end
  end
end
