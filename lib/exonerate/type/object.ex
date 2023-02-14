defmodule Exonerate.Type.Object do
  @moduledoc false

  alias Exonerate.Tools
  alias Exonerate.Combining

  @modules Combining.merge(%{
             "minProperties" => Exonerate.Filter.MinProperties,
             "maxProperties" => Exonerate.Filter.MaxProperties,
             "properties" => Exonerate.Filter.Properties,
             "additionalProperties" => Exonerate.Filter.AdditionalProperties,
             "required" => Exonerate.Filter.Required,
             "propertyNames" => Exonerate.Filter.PropertyNames,
             "patternProperties" => Exonerate.Filter.PatternProperties
           })

  @filters Map.keys(@modules)

  # additionalProperties also clobbers unevaluatedProperties
  def filter(subschema = %{"additionalProperties" => _, "unevaluatedProperties" => _}, name, pointer) do
    subschema
    |> Map.delete("unevaluatedProperties")
    |> filter(name, pointer)
  end

  def filter(subschema, name, pointer) do
    filters = filter_calls(subschema, name, pointer)

    call = Tools.pointer_to_fun_name(pointer, authority: name)

    quote do
      defp unquote(call)(content, path) when is_map(content) do
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
    should_traverse = should_traverse?(filters)

    filter_clauses =
      filters
      |> Enum.reject(&select_traverse?(&1, should_traverse))
      |> Enum.reject(&trivial?/1)
      |> Enum.map(fn {filter, _} ->
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
        unquote(traverse(filters, name, pointer, should_traverse))
      end
    end
  end

  defp trivial?({"additionalProperties", true}), do: true
  defp trivial?({"patternProperties", map}) when map_size(map) === 0, do: true
  defp trivial?(_), do: false

  defp should_traverse?(%{"additionalProperties" => false}), do: true
  defp should_traverse?(%{"additionalProperties" => %{}}), do: true
  defp should_traverse?(%{"propertyNames" => _}), do: true
  defp should_traverse?(%{"patternProperties" => map}) when map_size(map) > 0, do: true
  defp should_traverse?(_), do: false

  defp select_traverse?({"additionalProperties", false}, _), do: true
  defp select_traverse?({"additionalProperties", %{}}, _), do: true
  defp select_traverse?({"properties", _}, should_traverse), do: should_traverse
  defp select_traverse?({"propertyNames", _}, _), do: true
  defp select_traverse?({"patternProperties", map}, _) when map_size(map) > 0, do: true
  defp select_traverse?(_, _), do: false

  # additionalProperties MUST come at the end
  defp sort_filters({"additionalProperties", _}, _), do: false
  defp sort_filters(_, {"additionalProperties", _}), do: true
  # propertyNames MUST come at the start
  defp sort_filters({"propertyNames", _}, _), do: true
  defp sort_filters(_, {"propertyNames", _}), do: false
  defp sort_filters(a, b), do: a <= b

  def traverse(_, _, _, false), do: :ok

  def traverse(filters, name, pointer, true) do
    # clauses: should be the generated

    clauses =
      filters
      |> Enum.sort(&sort_filters/2)
      |> Enum.flat_map(&traversal(&1, name, pointer))
      |> append_fallthrough(filters)

    quote do
      Enum.reduce_while(content, :ok, fn
        _, error = {:error, _} ->
          {:halt, error}

        {key, value}, _ ->
          {:cont,
           cond do
             unquote(clauses)
           end}
      end)
    end
  end

  defp traversal({"properties", properties}, name, pointer) do
    Enum.flat_map(properties, fn
      {properties_key, _v} ->
        call =
          pointer
          |> JsonPointer.traverse(["properties", properties_key])
          |> Tools.pointer_to_fun_name(authority: name)

        quote do
          key === unquote(properties_key) -> unquote(call)(value, Path.join(path, key))
        end
    end)
  end

  defp traversal({"additionalProperties", selector}, name, pointer) when selector !== true do
    call =
      pointer
      |> JsonPointer.traverse("additionalProperties")
      |> Tools.pointer_to_fun_name(authority: name)

    # NB this is probably going to change when we start having :ok payloads
    ok_prong =
      quote do
        :ok -> :ok
      end

    error_prong =
      case selector do
        false ->
          quote do
            {:error, list} ->
              modified_errors =
                list
                |> Keyword.update!(:error_value, &{key, &1})
                |> Keyword.update!(:json_pointer, &Path.dirname(&1))

              {:error, modified_errors}
          end

        _ ->
          quote do
            error = {:error, _} -> error
          end
      end

    quote do
      true ->
        value
        |> unquote(call)(Path.join(path, key))
        |> case do
          unquote(ok_prong ++ error_prong)
        end
    end
  end

  defp traversal({"propertyNames", _selector}, name, pointer) do
    call =
      pointer
      |> JsonPointer.traverse("propertyNames")
      |> Tools.pointer_to_fun_name(authority: name)

    quote do
      (
        result = unquote(call)(key, Path.join(path, key))
        match?({:error, _}, result)
      ) ->
        result
    end
  end

  defp traversal({"patternProperties", patterns}, name, pointer) do
    Enum.flat_map(patterns, fn {pattern, _} ->
      call =
        pointer
        |> JsonPointer.traverse(["patternProperties", pattern])
        |> Tools.pointer_to_fun_name(authority: name)

      quote do
        Regex.match?(sigil_r(<<unquote(pattern)>>, []), key) ->
          unquote(call)(value, Path.join(path, key))
      end
    end)
  end

  defp traversal(_, _, _), do: []

  defp append_fallthrough(list, %{"additionalProperties" => what}) when what !== true, do: list

  defp append_fallthrough(list, _) do
    list ++
      quote do
        true -> :ok
      end
  end

  def accessories(schema, name, pointer, opts) do
    for filter_name <- @filters,
        Map.has_key?(schema, filter_name),
        not Combining.filter?(filter_name) do
      object_accessory(filter_name, schema, name, pointer, opts)
    end
  end

  defp object_accessory("properties", schema, name, pointer, opts) do
    if should_traverse?(schema) do
      schema
      |> Map.fetch!("properties")
      |> Map.keys()
      |> Enum.map(fn key ->
        new_pointer = JsonPointer.traverse(pointer, ["properties", key])

        quote do
          require Exonerate.Context
          Exonerate.Context.from_cached(unquote(name), unquote(new_pointer), unquote(opts))
        end
      end)
    else
      object_accessory("properties", name, pointer, opts)
    end
  end

  defp object_accessory(filter_name, _schema, name, pointer, opts) do
    object_accessory(filter_name, name, pointer, opts)
  end

  defp object_accessory(filter_name, name, pointer, opts) do
    module = @modules[filter_name]
    pointer = JsonPointer.traverse(pointer, filter_name)

    quote do
      require unquote(module)
      unquote(module).filter_from_cached(unquote(name), unquote(pointer), unquote(opts))
    end
  end
end
