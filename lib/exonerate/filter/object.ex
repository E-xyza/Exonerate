defmodule Exonerate.Filter.Object do
  @moduledoc false
  # the filter for "object" parameters

  @behaviour Exonerate.Filter

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

  defdelegate drop_type(state, type), to: Exonerate.Filter

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
      size_branch(schema, "maxProperties", schema_path) #++
      #required_branches(spec_path, spec.required) ++
      #property_dependencies(spec_path, spec.property_dependencies)

    quote do
      unquote_splicing(guard_properties)
      defp unquote(schema_path)(object, path) do
        #unquote(properties_filter_call(spec))
        #unquote_splicing(schema_dependencies_calls(spec))
        :ok
      end
      #unquote_splicing(properties_filter_helpers(spec))
      #unquote_splicing(schema_dependencies_helpers(spec))
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
        defp unquote(schema_path)(object, path) when unquote(size_comp) do
          Exonerate.mismatch(object, path, schema_subpath: unquote(op))
        end
      end]
    end

#    defp required_branches(_, nil), do: []
#    defp required_branches(path, requireds) do
#      requireds
#      |> Enum.with_index
#      |> Enum.map(fn {key, index} ->
#        subpath = "required/#{index}"
#        quote do
#          defp unquote(path)(object, path) when not is_map_key(object, unquote(key)) do
#            Exonerate.Builder.mismatch(object, path, subpath: unquote(subpath))
#          end
#        end
#      end)
#    end
#
#    defp property_dependencies(_, nil), do: []
#    defp property_dependencies(path, spec) do
#      Enum.flat_map(spec, fn {key, deps} ->
#        deps
#        |> Enum.with_index
#        |> Enum.map(fn {other_key, index} ->
#          subpath = "dependencies/#{key}/#{index}"
#          quote do
#            defp unquote(path)(object, path) when
#              is_map_key(object, unquote(key)) and not is_map_key(object, unquote(other_key)) do
#              Exonerate.Builder.mismatch(object, path, subpath: unquote(subpath))
#            end
#          end
#        end)
#      end)
#    end
#
#    defp properties_filter_call(spec = %{properties: p}) when not is_nil(p) do
#      spec_path = Exonerate.Builder.join(spec.path, "properties")
#      quote do
#        Enum.each(object, fn {k, v} ->
#          unquote(spec_path)(k, v, path)
#        end)
#      end
#    end
#    defp properties_filter_call(spec = %{pattern_properties: p}) when not is_nil(p) do
#      spec_path = Exonerate.Builder.join(spec.path, "patternProperties")
#      quote do
#        unquote(spec_path)(object, path)
#      end
#    end
#    defp properties_filter_call(spec = %{property_names: p}) when not is_nil(p) do
#      spec_path = Exonerate.Builder.join(spec.path, "propertyNames")
#      quote do
#        Enum.each(object, fn {key, param} ->
#          unquote(spec_path)(key, path)
#        end)
#      end
#    end
#    defp properties_filter_call(_), do: :ok
#
#    defp properties_filter_helpers(spec = %{properties: p}) when not is_nil(p) do
#      spec_path = Exonerate.Builder.join(spec.path, "properties")
#      {shims, helpers} = p
#      |> Enum.map(fn {k, v} ->
#        prop_path = Exonerate.Builder.join(spec_path, k)
#        {
#          quote do
#            defp unquote(spec_path)(unquote(k), value, path) do
#              unquote(prop_path)(value, Path.join(path, unquote(k)))
#            end
#          end,
#          Exonerate.Buildable.build(v)
#        }
#      end)
#      |> Enum.unzip
#
#      shims ++ [additional_properties_footer(spec)] ++ helpers
#    end
#    defp properties_filter_helpers(spec = %{pattern_properties: p}) when not is_nil(p) do
#      spec_path = Exonerate.Builder.join(spec.path, "patternProperties")
#      {calls, helpers} = p
#      |> Enum.map(fn {pattern, subspec} ->
#        pattern_path = Exonerate.Builder.join(spec_path, pattern)
#        {
#          quote do
#            checked! = if key =~ sigil_r(<<unquote(pattern)>>, []) do
#              unquote(pattern_path)(value, Path.join(path, key))
#              true
#            else
#              checked!
#            end
#          end,
#          Exonerate.Buildable.build(subspec)
#        }
#      end)
#      |> Enum.unzip
#
#      [quote do
#        defp unquote(spec_path)(object, path) do
#          Enum.each(object, fn {key, value} ->
#            checked! = false
#            unquote_splicing(calls)
#            unless checked! do
#              unquote(additional_properties_call(spec))
#            end
#          end)
#        end
#      end] ++ helpers ++ [additional_properties_helper(spec)]
#    end
#    defp properties_filter_helpers(%{property_names: p}) when not is_nil(p) do
#      [Exonerate.Buildable.build(p)]
#    end
#    defp properties_filter_helpers(_), do: []
#
#    defp schema_dependencies_calls(%{schema_dependencies: nil}), do: []
#    defp schema_dependencies_calls(spec) do
#      dependencies_path = Exonerate.Builder.join(spec.path, "dependencies")
#      Enum.map(spec.schema_dependencies, fn {key, _}->
#        schema_path = Exonerate.Builder.join(dependencies_path, key)
#        quote do
#          unquote(schema_path)(object, path)
#        end
#      end)
#    end
#
#    defp schema_dependencies_helpers(%{schema_dependencies: nil}), do: []
#    defp schema_dependencies_helpers(spec) do
#      Enum.map(spec.schema_dependencies, fn {_, inner_spec} ->
#        Exonerate.Buildable.build(inner_spec)
#      end)
#    end
#
#    defp additional_properties_footer(spec = %{additional_properties: permissive}) when permissive in [nil, true] do
#      spec_path = Exonerate.Builder.join(spec.path, "properties")
#      quote do
#        defp unquote(spec_path)(_key, _value, _path), do: :ok
#      end
#    end
#    defp additional_properties_footer(spec) do
#      spec_path = Exonerate.Builder.join(spec.path, "properties")
#      quote do
#        defp unquote(spec_path)(key, value, path) do
#          unquote(additional_properties_call(spec))
#        end
#        unquote(additional_properties_helper(spec))
#      end
#    end
#
#    defp additional_properties_call(%{additional_properties: nil}), do: :ok
#    defp additional_properties_call(spec = %{additional_properties: %{accept: false}}) do
#      additional_properties_path = Exonerate.Builder.join(spec.path, "additionalProperties")
#      quote do
#        try do
#          unquote(additional_properties_path)(value, path)
#        catch
#          {:mismatch, error} ->
#            throw {:mismatch, Keyword.put(error, :error_value, %{key => value})}
#        end
#      end
#    end
#    defp additional_properties_call(spec) do
#      additional_properties_path = Exonerate.Builder.join(spec.path, "additionalProperties")
#      quote do
#        unquote(additional_properties_path)(value, Path.join(path, key))
#      end
#    end
#
#    defp additional_properties_helper(%{additional_properties: nil}), do: :ok
#    defp additional_properties_helper(spec) do
#      Exonerate.Buildable.build(spec.additional_properties)
#    end
#  end

end
