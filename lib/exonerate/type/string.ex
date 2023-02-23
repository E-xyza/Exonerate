defmodule Exonerate.Type.String do
  @moduledoc false

  alias Exonerate.Draft
  alias Exonerate.Tools
  alias Exonerate.Combining

  @modules Combining.merge(%{
             "minLength" => Exonerate.Filter.MinLength,
             "maxLength" => Exonerate.Filter.MaxLength,
             "min-max-length" => Exonerate.Filter.MinMaxLength,
             "pattern" => Exonerate.Filter.Pattern
           })

  @module_keys Map.keys(@modules)

  defp filters(opts) do
    if Draft.before?(Keyword.get(opts, :draft, "2020-12"), "2019-09") do
      @module_keys -- ["$ref"]
    else
      @module_keys
    end
  end

  def filter(schema = %{"format" => "binary"}, name, pointer, opts) do
    filters = filter_calls(schema, name, pointer, opts)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_binary(content) do
        unquote(filters)
      end
    end
  end

  def filter(schema, name, pointer, opts) do
    filters = filter_calls(schema, name, pointer, opts)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    error_schema_pointer =
      pointer
      |> JsonPointer.traverse("type")
      |> JsonPointer.to_uri()

    quote do
      defp unquote(call)(content, path) when is_binary(content) do
        if String.valid?(content) do
          unquote(filters)
        else
          require Exonerate.Tools
          Exonerate.Tools.mismatch(content, unquote(error_schema_pointer), path)
        end
      end
    end
  end

  # maxLength and minLength can be combined
  defp combine_min_max(schema) do
    case schema do
      %{"maxLength" => _, "minLength" => _} ->
        schema
        |> Map.drop(["maxLength", "minLength"])
        |> Map.put("min-max-length", :ok)

      _ ->
        schema
    end
  end

  defp filter_calls(schema, name, pointer, opts) do
    schema
    |> combine_min_max
    |> Map.take(filters(opts))
    |> case do
      empty when empty === %{} ->
        :ok

      filters ->
        build_filters(filters, name, pointer)
    end
  end

  defp build_filters(filters, name, pointer) do
    filter_clauses =
      Enum.map(filters, fn {filter, _} ->
        call =
          pointer
          |> JsonPointer.traverse(Combining.adjust(filter))
          |> Tools.pointer_to_fun_name(authority: name)

        quote do
          :ok <- unquote(call)(content, path)
        end
      end)

    quote do
      with unquote_splicing(filter_clauses) do
        :ok
      end
    end
  end

  def accessories(schema, name, pointer, opts) do
    schema = combine_min_max(schema)

    for filter_name <- filters(opts),
        is_map_key(schema, filter_name),
        not Combining.filter?(filter_name) do
      module = @modules[filter_name]
      pointer = traverse(pointer, filter_name)

      quote do
        require unquote(module)
        unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
      end
    end
  end

  defp traverse(pointer, "min-max-length"), do: pointer
  defp traverse(pointer, filter), do: JsonPointer.traverse(pointer, filter)
end
