defmodule Exonerate.Context do
  @moduledoc false

  # a context is the representation of "parsing json at a given location"

  alias Exonerate.Cache
  alias Exonerate.Tools
  alias Exonerate.Type

  defmacro from_cached(name, pointer, opts) do
    name
    |> Cache.fetch!()
    |> JsonPointer.resolve!(pointer)
    |> to_quoted_function(name, pointer, opts)
    |> Tools.maybe_dump(opts)
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

  defp to_quoted_function(true, name, pointer, _opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      def unquote(call)(content, _path) do
        :ok
      end
    end
  end

  defp to_quoted_function(false, name, pointer, _opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    quote do
      @compile {:inline, [{unquote(call), 2}]}
      def unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
      end
    end
  end

  defp to_quoted_function(schema = %{"type" => type_or_types}, name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    type_filters =
      type_or_types
      |> List.wrap()
      |> Enum.map(&Type.module(&1).filter(schema, name, pointer))

    accessories =
      type_or_types
      |> List.wrap()
      |> Enum.flat_map(&Type.module(&1).accessories(schema, name, pointer, opts))

    schema_pointer = pointer
    |> JsonPointer.traverse("type")
    |> JsonPointer.to_uri

    quote do
      unquote(type_filters)

      def unquote(call)(content, path) do
        require Exonerate.Tools
        Exonerate.Tools.mismatch(content, unquote(schema_pointer), path)
      end

      unquote(accessories)
    end
  end

  defp to_quoted_function(_, call) do
    # assume "type" is a thing; but only filter when the type needs the filter.
    quote do
      def unquote(call)(content, path) do
        :ok
      end
    end
  end
end
