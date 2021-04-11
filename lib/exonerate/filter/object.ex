defmodule Exonerate.Filter.Object do
  @moduledoc false
  # the filter for "object" parameters

  alias Exonerate.Filter

  import Filter, only: [drop_type: 2]

  @behaviour Filter

  defguardp has_object_props(schema) when
    is_map_key(schema, "minProperties") or
    is_map_key(schema, "maxProperties") or
    is_map_key(schema, "required") or
    is_map_key(schema, "dependencies") or
    is_map_key(schema, "properties") or
    is_map_key(schema, "patternProperties") or
    is_map_key(schema, "propertyNames") or
    is_map_key(schema, "additionalProperties")

  @impl true
  def filter(schema, state = %{types: types})
      when has_object_props(schema) and is_map_key(types, :object) do
    {[object_filter(schema, state.path)], drop_type(state, :object)}
  end
  def filter(_schema, state) do
    {[], state}
  end

  # the scheme for testing objects is as follows:
  # - all tests that are guardable
  #   - generic filters
  #   - size
  #   - required
  #   - property dependencies
  # - properties filtering with its own pipeline
  #   - pattern_properties
  #   - property_names
  #   - properties
  #   - fallback on additional properties
  # - schema dependencies

  defp object_filter(schema, schema_path) do
    guard_properties =
      size_branch(schema, "minProperties", schema_path) ++
      size_branch(schema, "maxProperties", schema_path) ++
      required_branches(schema["required"], schema_path) ++
      property_dependencies(schema["dependencies"], schema_path)

    quote do
      unquote_splicing(guard_properties)
      defp unquote(schema_path)(object, path) when is_map(object) do
        unquote(properties_filter_call(schema, schema_path))
        unquote_splicing(schema_dependencies_calls(schema, schema_path))
        :ok
      end
      unquote_splicing(properties_filter_helpers(schema, schema_path))
      unquote_splicing(schema_dependencies_helpers(schema, schema_path))
    end
  end

  @operands %{
    "minProperties" => :<,
    "maxProperties" => :>
  }

  defp size_branch(schema, op, _) when not is_map_key(schema, op), do: []
  defp size_branch(schema, op, schema_path) do
    size_comp = {@operands[op], [], [quote do map_size(object) end, schema[op]]}
    [quote do
      defp unquote(schema_path)(object, path) when is_map(object) and unquote(size_comp) do
        Exonerate.mismatch(object, path, schema_subpath: unquote(op))
      end
    end]
  end

  defp required_branches(nil, _), do: []
  defp required_branches(requireds, schema_path) do
    requireds
    |> Enum.with_index
    |> Enum.map(fn {key, index} ->
      subpath = "required/#{index}"
      quote do
        defp unquote(schema_path)(object, path) when is_map(object) and not is_map_key(object, unquote(key)) do
          Exonerate.mismatch(object, path, schema_subpath: unquote(subpath))
        end
      end
    end)
  end

  defp property_dependencies(nil, _), do: []
  defp property_dependencies(deps_map, schema_path) do
    Enum.flat_map(deps_map, fn {key, deps} ->
      deps
      |> Enum.with_index
      |> Enum.flat_map(fn
        {other_key, index} when is_binary(other_key) ->
          subpath = "dependencies/#{key}/#{index}"
          [quote do
            defp unquote(schema_path)(object, path) when
              is_map(object) and
              is_map_key(object, unquote(key)) and not
              is_map_key(object, unquote(other_key)) do
              Exonerate.mismatch(object, path, schema_subpath: unquote(subpath))
            end
          end]
        _ -> []
      end)
    end)
  end

  defp properties_filter_call(%{"properties" => _}, schema_path) do
    props_path = Exonerate.join(schema_path, "properties")
    quote do
      Enum.each(object, fn {k, v} ->
        unquote(props_path)(k, v, path)
      end)
    end
  end
  defp properties_filter_call(%{"patternProperties" => _}, schema_path) do
    props_path = Exonerate.join(schema_path, "patternProperties")
    quote do
      unquote(props_path)(object, path)
    end
  end
  defp properties_filter_call(%{"propertyNames" => _}, schema_path) do
    props_path = Exonerate.join(schema_path, "propertyNames")
    quote do
      Enum.each(object, fn {key, param} ->
        unquote(props_path)(key, path)
      end)
    end
  end
  defp properties_filter_call(_, _), do: :ok

  defp properties_filter_helpers(schema = %{"properties" => p}, schema_path) do
    props_path = Exonerate.join(schema_path, "properties")
    {shims, helpers} = p
    |> Enum.map(fn {k, v} ->
      prop_path = Exonerate.join(props_path, k)
      {
        quote do
          defp unquote(props_path)(unquote(k), value, path) do
            unquote(prop_path)(value, Path.join(path, unquote(k)))
          end
        end,
        Filter.from_schema(v, prop_path)
      }
    end)
    |> Enum.unzip

    shims ++ [additional_properties_footer(schema, schema_path)] ++ helpers
  end
  defp properties_filter_helpers(schema = %{"patternProperties" => p}, schema_path) do
    props_path = Exonerate.join(schema_path, "patternProperties")

    {calls, helpers} = p
    |> Enum.map(fn {pattern, subspec} ->
      pattern_path = Exonerate.join(props_path, pattern)
      {
        quote do
          checked! = if key =~ sigil_r(<<unquote(pattern)>>, []) do
            unquote(pattern_path)(value, Path.join(path, key))
            true
          else
            checked!
          end
        end,
        Filter.from_schema(subspec, pattern_path)
      }
    end)
    |> Enum.unzip

    [quote do
      defp unquote(props_path)(object, path) do
        Enum.each(object, fn {key, value} ->
          checked! = false
          unquote_splicing(calls)
          unless checked! do
            unquote(additional_properties_call(schema, schema_path))
          end
        end)
      end
    end] ++ helpers ++ [additional_properties_helper(schema, schema_path)]
  end
  defp properties_filter_helpers(%{"propertyNames" => p}, schema_path) do
    property_names_path = Exonerate.join(schema_path, "propertyNames")
    [Filter.from_schema(p, property_names_path)]
  end
  defp properties_filter_helpers(_, _), do: []

  defp schema_dependencies_calls(%{"dependencies" => deps}, schema_path) do
    deps_root = Exonerate.join(schema_path, "dependencies")
    deps
    |> Enum.filter(&is_map(elem(&1, 1)))
    |> Enum.map(fn {key, _}->
      dep_path = Exonerate.join(deps_root, key)
      quote do
        unquote(dep_path)(object, path)
      end
    end)
  end
  defp schema_dependencies_calls(_spec, _path), do: []

  defp schema_dependencies_helpers(%{"dependencies" => deps}, schema_path) do
    deps_root = Exonerate.join(schema_path, "dependencies")
    deps
    |> Enum.filter(&is_map(elem(&1, 1)))
    |> Enum.map(fn {key, inner_spec} ->
      dep_path = Exonerate.join(deps_root, key)
      inner_spec
      |> Map.put("type", "object")
      |> Filter.from_schema(dep_path)
    end)
  end
  defp schema_dependencies_helpers(_spec, _path), do: []

  defp additional_properties_footer(
      schema = %{"additionalProperties" => aps},
      schema_path) when aps != true do

    props_path = Exonerate.join(schema_path, "properties")
    quote do
      defp unquote(props_path)(key, value, path) do
        unquote(additional_properties_call(schema, schema_path))
      end
      unquote(additional_properties_helper(schema, schema_path))
    end
  end
  defp additional_properties_footer(_, schema_path) do
    props_path = Exonerate.join(schema_path, "properties")
    quote do
      defp unquote(props_path)(_key, _value, _path), do: :ok
    end
  end

  defp additional_properties_call(%{"additionalProperties" => nil}, _), do: :ok
  defp additional_properties_call(%{"additionalProperties" => false}, schema_path) do
    additional_props_path = Exonerate.join(schema_path, "additionalProperties")
    quote do
      try do
        unquote(additional_props_path)(value, path)
      catch
        {:mismatch, error} ->
          throw {:mismatch, Keyword.put(error, :error_value, %{key => value})}
      end
    end
  end
  defp additional_properties_call(%{"additionalProperties" => _}, schema_path) do
    additional_properties_path = Exonerate.join(schema_path, "additionalProperties")
    quote do
      unquote(additional_properties_path)(value, Path.join(path, key))
    end
  end
  defp additional_properties_call(_, _), do: :ok

  @spec additional_properties_helper(Type.json, atom) :: Macro.t
  defp additional_properties_helper(%{"additionalProperties" => nil}, _), do: :ok
  defp additional_properties_helper(%{"additionalProperties" => inner_schema}, schema_path) do
    additional_properties_path = Exonerate.join(schema_path, "additionalProperties")
    Filter.from_schema(inner_schema, additional_properties_path)
  end
  defp additional_properties_helper(_, _), do: :ok
end
