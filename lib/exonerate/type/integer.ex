defmodule Exonerate.Type.Integer do
  @moduledoc false

  alias Exonerate.Tools

  @modules %{
    "maximum" => Exonerate.Filter.Maximum,
    "minimum" => Exonerate.Filter.Minimum,
    "exclusiveMaximum" => Exonerate.Filter.ExclusiveMaximum,
    "exclusiveMinimum" => Exonerate.Filter.ExclusiveMinimum,
    "multipleOf" => Exonerate.Filter.MultipleOf
  }
  @filters Map.keys(@modules)

  def filter(schema, name, pointer) do
    filters = filter_calls(schema, name, pointer)
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_integer(content) do
        unquote(filters)
      end
    end
  end

  defp filter_calls(schema, name, pointer) do
    case Map.take(schema, @filters) do
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
          |> JsonPointer.traverse(filter)
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
    for filter_name <- @filters, schema[filter_name] do
      module = @modules[filter_name]
      pointer = JsonPointer.traverse(pointer, filter_name)

      quote do
        require unquote(module)
        unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
      end
    end
  end
end
