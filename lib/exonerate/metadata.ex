defmodule Exonerate.Metadata do
  @moduledoc false

  alias Exonerate.Tools

  # defp functions can't create metadata.
  defmacro functions(:defp, _, _, _), do: nil

  defmacro functions(type, function_name, resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_functions(type, function_name, metadatas(opts))
  end

  def schema(_, :defp, _), do: nil

  def schema(schema_str, type, function_name, opts) do
    metadata_opts = List.wrap(opts[:metadata])
    schema_value = Jason.decode!(schema_str)

    if metadata_opts == [true] or :schema in metadata_opts do
      quote do
        unquote(type)(unquote(function_name)(:schema), do: unquote(Macro.escape(schema_value)))
      end
    end
  end

  # note that the schema metadata isn't here because this function would pull the
  # degeneracy-optimized schema from the cache, which is not what we want.  Instead,
  # we generate schema metadata at the callsite using the above ast function.
  @all_metadata [:id, :schema_id, :title, :description, :examples, :default]

  defp metadatas(opts) do
    case opts[:metadata] do
      true -> @all_metadata
      nil_or_list -> List.wrap(nil_or_list)
    end
  end

  defp build_functions(schema, _, _, _) when is_boolean(schema), do: nil

  defp build_functions(schema, type, function_name, metadatas) do
    quote do
      unquote(id(schema, type, function_name, metadatas))
      unquote(schema_id(schema, type, function_name, metadatas))
      unquote(title(schema, type, function_name, metadatas))
      unquote(description(schema, type, function_name, metadatas))
      unquote(examples(schema, type, function_name, metadatas))
      unquote(default(schema, type, function_name, metadatas))
    end
  end

  defp id(schema, type, function_name, metadatas) do
    if id = :id in metadatas and (schema["$id"] || schema["id"]) do
      quote do
        unquote(type)(unquote(function_name)(:id), do: unquote(id))
      end
    end
  end

  defp schema_id(schema, type, function_name, metadatas) do
    if schema_id = :schema_id in metadatas and schema["$schema"] do
      quote do
        unquote(type)(unquote(function_name)(:schema_id), do: unquote(schema_id))
      end
    end
  end

  defp title(schema, type, function_name, metadatas) do
    if title = :title in metadatas and schema["title"] do
      quote do
        unquote(type)(unquote(function_name)(:title), do: unquote(title))
      end
    end
  end

  defp description(schema, type, function_name, metadatas) do
    if description = :description in metadatas and schema["description"] do
      quote do
        unquote(type)(unquote(function_name)(:description), do: unquote(description))
      end
    end
  end

  defp examples(schema, type, function_name, metadatas) do
    if examples = :examples in metadatas and schema["examples"] do
      quote do
        unquote(type)(unquote(function_name)(:examples), do: unquote(Macro.escape(examples)))
      end
    end
  end

  defp default(schema, type, function_name, metadatas) do
    if default = :default in metadatas and schema["default"] do
      quote do
        unquote(type)(unquote(function_name)(:default), do: unquote(Macro.escape(default)))
      end
    end
  end
end
