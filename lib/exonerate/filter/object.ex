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
  #   - properties
  #   - pattern_properties
  #   - fallback on additional properties
  # - or: property_names
  # - schema dependencies

  defp object_filter(schema, schema_path) do
    guard_properties =
      size_branch(schema, "minProperties", schema_path) ++
      size_branch(schema, "maxProperties", schema_path) ++
      required_branches(schema["required"], schema_path) ++
      property_dependencies(schema["dependencies"], schema_path)

    q = quote do
      unquote_splicing(guard_properties)
      unquote(property_names_validator(schema, schema_path))
      unquote(properties_validator(schema, schema_path))
      unquote_splicing(properties_helper(schema, schema_path))
      unquote(pattern_properties_helper(schema, schema_path))
      unquote(additional_properties_helper(schema, schema_path))
      unquote_splicing(schema_dependencies_helpers(schema, schema_path))
    end
    #if Atom.to_string(schema_path) =~ "test0" do
    #  q |> Macro.to_string |> IO.puts()
    #end
    q
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

  defp property_names_validator(%{"property_names" => _names}, schema_path) do
    quote do
      defp unquote(schema_path)(object, path) when is_map(object) do
        :ok
      end
    end
  end
  defp property_names_validator(_, _), do: nil

  defp properties_validator(spec, schema_path) when
    is_map_key(spec, "properties") or
    is_map_key(spec, "patternProperties") or
    is_map_key(spec, "additionalProperties") do
    quote do
      defp unquote(schema_path)(object, path) when is_map(object) do
        Enum.each(object, fn {k, v} ->
          unquote(properties_call(spec, schema_path)) ||
          unquote(pattern_properties_call(spec, schema_path)) ||
          unquote(additional_properties_call(spec, schema_path))
        end)
      end
    end
  end
  defp properties_validator(_spec, schema_path) do
    quote do
      defp unquote(schema_path)(object, path) when is_map(object), do: :ok
    end
  end

  defp properties_call(spec, schema_path)
      when is_map_key(spec, "properties") do
    call = Exonerate.join(schema_path, "properties")
    quote do
      unquote(call)(k, v, Path.join(path, k))
    end
  end
  defp properties_call(_, _), do: nil

  defp pattern_properties_call(spec, schema_path)
      when is_map_key(spec, "patternProperties") do
    call = Exonerate.join(schema_path, "patternProperties")
    quote do
      unquote(call)(k, v, Path.join(path, k))
    end
  end
  defp pattern_properties_call(_, _), do: nil

  defp additional_properties_call(spec, schema_path)
      when is_map_key(spec, "additionalProperties") do
    call = Exonerate.join(schema_path, "additionalProperties")
    quote do
      unquote(call)(v, Path.join(path, k))
    end
  end
  defp additional_properties_call(_, _), do: nil

  @spec properties_helper(Type.json, atom) :: Macro.t
  defp properties_helper(%{"properties" => nil}, _), do: []
  defp properties_helper(%{"properties" => properties_schemata}, schema_path) do
    properties_path = Exonerate.join(schema_path, "properties")
    {matches, clauses} = properties_schemata
    |> Enum.map(fn {key, schema} ->
      key_path = Exonerate.join(properties_path, key)
      match = quote do
        defp unquote(properties_path)(unquote(key), value, path) do
          unquote(key_path)(value, path)
        end
      end
      clause = Filter.from_schema(schema, key_path)
      {match, clause}
    end)
    |> Enum.unzip

    default_match = quote do
      defp unquote(properties_path)(_, _, _), do: false
    end

    matches ++ [default_match] ++ clauses
  end
  defp properties_helper(_, _), do: []

  @spec pattern_properties_helper(Type.json, atom) :: Macro.t
  defp pattern_properties_helper(%{"patternProperties" => nil}, _), do: :ok
  defp pattern_properties_helper(%{"patternProperties" => inner_schema}, schema_path) do
    pattern_properties_path = Exonerate.join(schema_path, "patternProperties")
    {matches, clauses} = inner_schema
    |> Enum.map(fn
      {k, v} ->
        call = Exonerate.join(pattern_properties_path, k)
        match = quote do
          Regex.match?(sigil_r(<<unquote(k)>>, []), key) and unquote(call)(value, Path.join(path, key))
        end
        clause = Filter.from_schema(v, call)

        {match, clause}
    end)
    |> Enum.unzip

    quote do
      defp unquote(pattern_properties_path)(key, value, path) do
        unquote_splicing(matches)
        :ok
      end
      unquote_splicing(clauses)
    end
  end
  defp pattern_properties_helper(_, _), do: :ok

  @spec additional_properties_helper(Type.json, atom) :: Macro.t
  defp additional_properties_helper(%{"additionalProperties" => nil}, _), do: :ok
  defp additional_properties_helper(%{"additionalProperties" => inner_schema}, schema_path) do
    additional_properties_path = Exonerate.join(schema_path, "additionalProperties")
    Filter.from_schema(inner_schema, additional_properties_path)
  end
  defp additional_properties_helper(_, _), do: :ok

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
end
