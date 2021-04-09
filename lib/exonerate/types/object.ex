defmodule Exonerate.Types.Object do
  @enforce_keys [:path]
  @props ~w(
    min_properties
    max_properties
    required
    property_dependencies
    property_names
    properties
    pattern_properties
    additional_properties
    schema_dependencies
    )a

  defstruct @enforce_keys ++ @props

  alias Exonerate.Types.String
  alias Exonerate.Builder

  def build(schema, path) do
    properties = if props = schema["properties"] do
      props
      |> Enum.map(fn {prop, inner_schema} ->
        prop_path = path
        |> Builder.join("properties")
        |> Builder.join(prop)

        {prop, Builder.to_struct(inner_schema, prop_path)}
      end)
      |> Map.new
    end

    pattern_properties = if props = schema["patternProperties"] do
      props
      |> Enum.map(fn {prop, spec} ->
        prop_path = path
        |> Builder.join("patternProperties")
        |> Builder.join(prop)

        {prop, Builder.to_struct(spec, prop_path)}
      end)
      |> Map.new
    end

    property_names = if props = schema["propertyNames"] do
      String.build(props, Builder.join(path, "propertyNames"))
    end

    additional_properties = case schema["additionalProperties"] do
      default when default in [true, nil] -> nil
      props -> Builder.to_struct(props, Builder.join(path, "additionalProperties"))
    end

    {property_dependencies, schema_dependencies} = if props = schema["dependencies"] do
      props
      |> Enum.map(fn
        {key, subschema} when is_map(subschema)->
          prop_path = path
          |> Builder.join("dependencies")
          |> Builder.join(key)

          {key, subschema |> Map.put("type", "object") |> Builder.to_struct(prop_path)}
        kv -> kv
        end)
      |> Enum.split_with(fn {_k, v} -> is_list(v) end)
    else
      {nil, nil}
    end


    %__MODULE__{
      path: path,
      # guardable tests
      min_properties: schema["minProperties"],
      max_properties: schema["maxProperties"],
      required: schema["required"],
      property_dependencies: property_dependencies,
      # property filtering tests
      properties:     properties,
      pattern_properties: pattern_properties,
      property_names: property_names,
      additional_properties: additional_properties,
      # final tests
      schema_dependencies: schema_dependencies,
    }
  end

  def props, do: @props

  defimpl Exonerate.Buildable do

    # the scheme for testing objects is as follows:
    # - all tests that are guardable
    #   - size
    #   - required
    #   - property dependencies
    # - properties filtering with its own pipeline
    #   - pattern_properties
    #   - property_names
    #   - properties
    #   - fallback on additional properties
    # - schema dependencies

    def build(spec = %{path: spec_path}) do
      guard_properties =
        size_branch(spec_path, "minProperties", spec.min_properties) ++
        size_branch(spec_path, "maxProperties", spec.max_properties) ++
        required_branch(spec_path, spec.required) ++
        property_dependencies(spec_path, spec.property_dependencies)

      q = quote do
        defp unquote(spec_path)(value, path) when not is_map(value) do
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        end
        unquote_splicing(guard_properties)
        defp unquote(spec_path)(object, path) do
          unquote(properties_filter_call(spec))
          unquote(schema_dependencies_call(spec))
        end
        unquote_splicing(properties_filter_helpers(spec))
        unquote_splicing(schema_dependencies_helpers(spec))
      end
      spec.path == :"address1#" && Macro.to_string(q) |> IO.puts
      q
    end

    @operands %{
      "minProperties" => :<,
      "maxProperties" => :>
    }

    defp size_branch(_, _, nil), do: []
    defp size_branch(path, op, value) do
      size_comp = {@operands[op], [], [quote do map_size(object) end, value]}
      [quote do
        defp unquote(path)(object, path) when unquote(size_comp) do
          Exonerate.Builder.mismatch(object, path, subpath: unquote(op))
        end
      end]
    end

    defp required_branch(_, nil), do: []
    defp required_branch(path, requireds) do
      required_guards = requireds
      |> Enum.map(&quote do not is_map_key(object, unquote(&1)) end)
      |> Enum.reduce(&quote do unquote(&1) or unquote(&2) end)

      [quote do
        defp unquote(path)(object, path) when unquote(required_guards) do
          Exonerate.Builder.mismatch(object, path, subpath: "required")
        end
      end]
    end

    defp property_dependencies(_, nil), do: []
    defp property_dependencies(path, spec) do
      spec
      |> Enum.map(fn {key, deps} ->
        dep_guard = deps
        |> Enum.map(&quote do not is_map_key(object, unquote(&1)) end)
        |> Enum.reduce(&quote do unquote(&1) or unquote(&2) end)

        quote do
          defp unquote(path)(object, path) when is_map_key(object, unquote(key)) and unquote(dep_guard) do
            Exonerate.Builder.mismatch(object, path, subpath: "dependencies")
          end
        end
      end)
    end

    defp properties_filter_call(spec = %{properties: p}) when not is_nil(p) do
      props_path = Exonerate.Builder.join(spec.path, "properties")
      quote do
        Enum.each(object, fn {k, v} ->
          unquote(props_path)(k, v, path)
        end)
      end
    end
    defp properties_filter_call(spec = %{pattern_properties: p}) when not is_nil(p) do
      props_path = Exonerate.Builder.join(spec.path, "patternProperties")
      quote do
        unquote(props_path)(object, path)
      end
    end
    defp properties_filter_call(spec = %{property_names: p}) when not is_nil(p) do
      props_path = Exonerate.Builder.join(spec.path, "propertyNames")
      quote do
        Enum.each(object, fn {key, param} ->
          unquote(props_path)(key, path)
        end)
      end
    end
    defp properties_filter_call(_), do: :ok

    defp properties_filter_helpers(spec = %{properties: p}) when not is_nil(p) do
      props_path = Exonerate.Builder.join(spec.path, "properties")
      {shims, helpers} = p
      |> Enum.map(fn {k, v} ->
        prop_path = Exonerate.Builder.join(props_path, k)
        {quote do
          defp unquote(props_path)(unquote(k), value, path) do
            unquote(prop_path)(value, Path.join(path, unquote(k)))
          end
        end,
        Exonerate.Buildable.build(v)}
      end)
      |> Enum.unzip

      shims ++ helpers
    end
    defp properties_filter_helpers(spec = %{pattern_properties: p}) when not is_nil(p) do
      props_path = Exonerate.Builder.join(spec.path, "patternProperties")
      [quote do
        defp unquote(props_path)(_, _) do
        :ok
        end
      end]
    end
    defp properties_filter_helpers(%{property_names: p}) when not is_nil(p) do
      [Exonerate.Buildable.build(p)]
    end

    defp schema_dependencies_call(_), do: :ok

    #defp properties_filter(path, props = %{properties: nil, pattern_properties: nil, property_names: nil}) do
    #  [quote do
    #    defp unquote(path)(_, _) do
    #      unquote(schema_dependency_call(path, props))
    #    end
    #  end] ++
    #  schema_dependency_helpers(path, props)
    #end
    #defp properties_filter(path, spec = %{properties: _, pattern_properties: nil, property_names: nil}) do
    #  [quote do
    #    defp unquote(path)(object, path) do
    #      Enum.each(object, fn {k, v} ->
    #        unless (error = unquote(:"#{path}-properties")(k, v, path)) == :ok do
    #          throw error
    #        end
    #      end)
    #      unquote(schema_dependency_call(path, spec))
    #    catch
    #      error = {:mismatch, _} -> error
    #    end
    #  end]
    #  ++ properties_helpers(path, spec)
    #  ++ schema_dependency_helpers(:"#{path}-dependencies", spec)
    #end
    #defp properties_filter(path, spec = %{properties: nil, pattern_properties: _, property_names: nil}) do
    #  patterns = Map.keys(spec.pattern_properties)
    #  [quote do
    #    defp unquote(path)(object, path) do
    #      Enum.each(object, fn {key, param} ->
    #        unless (error = unquote(:"#{path}-pattern_properties")(key, param, path, unquote(patterns))) == :ok do
    #          throw error
    #        end
    #      end)
    #      unquote(schema_dependency_call(path, spec))
    #    catch
    #      error = {:mismatch, _} -> error
    #    end
    #  end]
    #  ++ pattern_properties_helpers(path, spec)
    #  ++ schema_dependency_helpers(:"#{path}-dependencies", spec)
    #end
    #defp properties_filter(path, spec = %{properties: nil, pattern_properties: nil, property_names: _}) do
    #  [quote do
    #    defp unquote(path)(object, path) do
    #      Enum.each(object, fn {key, param} ->
    #        unless (error = unquote(:"#{path}-property_names")(key, param, path)) == :ok do
    #          throw error
    #        end
    #      end)
    #      unquote(schema_dependency_call(path, spec))
    #    catch
    #      error = {:mismatch, _} -> error
    #    end
    #  end]
    #  ++ property_names_helpers(path, spec)
    #  ++ schema_dependency_helpers(:"#{path}-dependencies", spec)
    #end
#
    #defp properties_helpers(path, spec = %{properties: properties}) do
    #  specs = properties
    #  |> Map.values
    #  |> Enum.map(&Exonerate.Buildable.build/1)
#
    #  Enum.map(properties, fn {key, spec} ->
    #    quote do
    #      defp unquote(:"#{path}-properties")(unquote(key), param, path) do
    #        unquote(spec.path)(param, path)
    #      end
    #    end
    #  end) ++ filters_fallback(:"#{path}-properties", path, spec) ++ specs
    #end
#
    #defp pattern_properties_helpers(path, spec = %{pattern_properties: pattern_properties}) do
    #  {filters, specs} = pattern_properties
    #  |> Enum.map(fn {key, value} ->
    #    {
    #      quote do
    #        defp unquote(:"#{path}-pattern_properties")(key, param, path, [unquote(key) | rest]) do
    #          if key =~ sigil_r(<<unquote(key)>>, []) do
    #            unquote(:"#{path}-pattern_properties-#{key}")(param, path)
    #          else
    #            unquote(:"#{path}-pattern_properties")(key, param, path, rest)
    #          end
    #        end
    #      end,
    #      Exonerate.Buildable.build(value)
    #    }
    #  end)
    #  |> Enum.unzip
#
    #  fallback = if spec.additional_properties do
    #    [quote do
    #      defp unquote(:"#{path}-pattern_properties")(key, param, path, []) do
    #        unquote(:"#{path}-additional_properties")(param, path)
    #      end
    #    end]
    #  else
    #    [quote do
    #      defp unquote(:"#{path}-pattern_properties")(_, _), do: :ok
    #    end]
    #  end
#
    #  filters ++ fallback ++ filters_fallback(path, spec) ++ specs
    #end
#
    #defp property_names_helpers(path, spec) do
    #  [quote do
    #    defp unquote(:"#{path}-property_names")(key, _, path) do
    #      unquote(:"#{path}-property_names")(key, path)
    #    end
    #  end] ++ [Exonerate.Buildable.build(spec.property_names)]
    #end
#
    #defp filters_fallback(path, props), do: filters_fallback(path, path, props)
    #defp filters_fallback(caller, _parent, %{additional_properties: nil}) do
    #  [quote do
    #    defp unquote(caller)(_, value, path), do: :ok
    #  end]
    #end
    #defp filters_fallback(caller, parent, %{additional_properties: additional_properties}) do
    #  [
    #    quote do
    #      defp unquote(caller)(_, value, path) do
    #        unquote(:"#{parent}-additional_properties")(value, path)
    #      end
    #    end
    #  ] ++ [Exonerate.Buildable.build(additional_properties)]
    #end
#
    #defp schema_dependency_call(_path, %{schema_dependencies: nil}), do: :ok
    #defp schema_dependency_call(path, _) do
    #  quote do
    #    unquote(:"#{path}-dependencies")(object, path)
    #  end
    #end
#
    #defp schema_dependency_helpers(_path, %{schema_dependencies: nil}), do: []
    #defp schema_dependency_helpers(path, %{schema_dependencies: schema_dependencies}) do
    #  {calls, deps} = schema_dependencies
    #  |> Enum.map(fn {key, spec} ->
    #    {
    #      quote do
    #        defp unquote(path)(object, unquote(key), path) do
    #          unquote(:"#{path}-#{key}")(object, path)
    #        end
    #      end,
    #      Exonerate.Buildable.build(spec)
    #    }
    #  end)
    #  |> Enum.unzip
#
    #  [quote do
    #    defp unquote(path)(object, path) do
    #      Enum.each(object, fn {k, _} ->
    #        unless (error = unquote(path)(object, k, path)) == :ok do
    #          throw error
    #        end
    #      end)
    #    catch
    #      error = {:mismatch, _} -> error
    #    end
    #  end] ++ calls ++ [quote do
    #    defp unquote(path)(_, _, _), do: :ok
    #  end] ++ deps
    #end

    defp properties_filter_helpers(_), do: []

    defp schema_dependencies_helpers(_), do: []
  end
end
