defmodule Exonerate.Context do
  @moduledoc false

  # a context is the representation of "parsing json at a given location"

  alias Exonerate.Cache
  alias Exonerate.Tools
  alias Exonerate.Type

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

  # don't normally use the brackted alias format but it makes sense here.
  alias Exonerate.Type.{Array, Boolean, Integer, Null, Number, Object, String}

  @filter_map %{
    "array" => Array,
    "boolean" => Boolean,
    "integer" => Integer,
    "null" => Null,
    "number" => Number,
    "object" => Object,
    "string" => String
  }

  defp type_filters(call, schema = %{"type" => type_or_types}) do
    passthroughs =
      type_or_types
      |> List.wrap()
      |> Enum.map(&Type.module(&1).type_filter(call, schema))

    quote do
      unquote(passthroughs)

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

  defp type_filter(type, schema) do
  end
end
