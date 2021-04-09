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

  def build(path, params) do
    properties = if props = params["properties"] do
      props
      |> Enum.map(fn {prop, spec} ->
        {prop, Builder.to_struct(spec, :"#{path}-properties-#{prop}")}
      end)
      |> Map.new
    end

    pattern_properties = if props = params["patternProperties"] do
      props
      |> Enum.map(fn {prop, spec} ->
        {prop, Builder.to_struct(spec, :"#{path}-pattern_properties-#{prop}")}
      end)
      |> Map.new
    end

    property_names = if props = params["propertyNames"] do
      String.build(:"#{path}-property_names", props)
    end

    additional_properties = case params["additionalProperties"] do
      default when default in [true, nil] -> nil
      props -> Builder.to_struct(props, :"#{path}-additional_properties")
    end

    {property_dependencies, schema_dependencies} = if props = params["dependencies"] do
      props
      |> Enum.map(fn
        {k, v} when is_map(v)->
          {k, v |> Map.put("type", "object") |> Builder.to_struct(:"#{path}-dependencies-#{k}")}
        kv -> kv
        end)
      |> Enum.split_with(fn {_k, v} -> is_list(v) end)
    else
      {nil, nil}
    end


    %__MODULE__{
      path: path,
      # guardable tests
      min_properties: params["minProperties"],
      max_properties: params["maxProperties"],
      required: params["required"],
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
    #   - property_dependencies
    # - properties filtering with its own pipeline
    #   - pattern_properties
    #   - property_names
    #   - properties
    #   - fallback on additional properties
    # - schema dependencies

    def build(params = %{path: path}) do
      guard_properties =
        size_branch(path, :<, params.min_properties) ++
        size_branch(path, :>, params.max_properties) ++
        required_branch(path, params.required) ++
        property_dependencies(path, params.property_dependencies)

      quote do
        defp unquote(path)(value, path) when not is_map(value) do
          {:mismatch, {path, value}}
        end
        unquote_splicing(guard_properties)
        unquote_splicing(properties_filter(path, params))
      end
    end

    defp size_branch(_, _, nil), do: []
    defp size_branch(path, op, value) do
      size_comp = {op, [], [quote do map_size(object) end, value]}
      [quote do
        defp unquote(path)(object, path) when unquote(size_comp) do
          {:mismatch, {path, object}}
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
          {:mismatch, {path, object}}
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
            {:mismatch, {path, object}}
          end
        end
      end)
    end

    defp properties_filter(path, props = %{properties: nil, pattern_properties: nil, property_names: nil}) do
      [quote do
        defp unquote(path)(_, _) do
          unquote(schema_dependency_call(path, props))
        end
      end] ++
      schema_dependency_helpers(path, props)
    end
    defp properties_filter(path, params = %{properties: _, pattern_properties: nil, property_names: nil}) do
      [quote do
        defp unquote(path)(object, path) do
          Enum.each(object, fn {k, v} ->
            unless (error = unquote(:"#{path}-properties")(k, v, path)) == :ok do
              throw error
            end
          end)
          unquote(schema_dependency_call(path, params))
        catch
          error = {:mismatch, _} -> error
        end
      end]
      ++ properties_helpers(path, params)
      ++ schema_dependency_helpers(:"#{path}-dependencies", params)
    end
    defp properties_filter(path, params = %{properties: nil, pattern_properties: _, property_names: nil}) do
      patterns = Map.keys(params.pattern_properties)
      [quote do
        defp unquote(path)(object, path) do
          Enum.each(object, fn {key, param} ->
            unless (error = unquote(:"#{path}-pattern_properties")(key, param, path, unquote(patterns))) == :ok do
              throw error
            end
          end)
          unquote(schema_dependency_call(path, params))
        catch
          error = {:mismatch, _} -> error
        end
      end]
      ++ pattern_properties_helpers(path, params)
      ++ schema_dependency_helpers(:"#{path}-dependencies", params)
    end
    defp properties_filter(path, params = %{properties: nil, pattern_properties: nil, property_names: _}) do
      [quote do
        defp unquote(path)(object, path) do
          Enum.each(object, fn {key, param} ->
            unless (error = unquote(:"#{path}-property_names")(key, param, path)) == :ok do
              throw error
            end
          end)
          unquote(schema_dependency_call(path, params))
        catch
          error = {:mismatch, _} -> error
        end
      end]
      ++ property_names_helpers(path, params)
      ++ schema_dependency_helpers(:"#{path}-dependencies", params)
    end

    defp properties_helpers(path, params = %{properties: properties}) do
      specs = properties
      |> Map.values
      |> Enum.map(&Exonerate.Buildable.build/1)

      Enum.map(properties, fn {key, spec} ->
        quote do
          defp unquote(:"#{path}-properties")(unquote(key), param, path) do
            unquote(spec.path)(param, path)
          end
        end
      end) ++ filters_fallback(:"#{path}-properties", path, params) ++ specs
    end

    defp pattern_properties_helpers(path, params = %{pattern_properties: pattern_properties}) do
      {filters, specs} = pattern_properties
      |> Enum.map(fn {key, value} ->
        {
          quote do
            defp unquote(:"#{path}-pattern_properties")(key, param, path, [unquote(key) | rest]) do
              if key =~ sigil_r(<<unquote(key)>>, []) do
                unquote(:"#{path}-pattern_properties-#{key}")(param, path)
              else
                unquote(:"#{path}-pattern_properties")(key, param, path, rest)
              end
            end
          end,
          Exonerate.Buildable.build(value)
        }
      end)
      |> Enum.unzip

      fallback = if params.additional_properties do
        [quote do
          defp unquote(:"#{path}-pattern_properties")(key, param, path, []) do
            unquote(:"#{path}-additional_properties")(param, path)
          end
        end]
      else
        [quote do
          defp unquote(:"#{path}-pattern_properties")(_, _), do: :ok
        end]
      end

      filters ++ fallback ++ filters_fallback(path, params) ++ specs
    end

    defp property_names_helpers(path, params) do
      [quote do
        defp unquote(:"#{path}-property_names")(key, _, path) do
          unquote(:"#{path}-property_names")(key, path)
        end
      end] ++ [Exonerate.Buildable.build(params.property_names)]
    end

    defp filters_fallback(path, props), do: filters_fallback(path, path, props)
    defp filters_fallback(caller, _parent, %{additional_properties: nil}) do
      [quote do
        defp unquote(caller)(_, value, path), do: :ok
      end]
    end
    defp filters_fallback(caller, parent, %{additional_properties: additional_properties}) do
      [
        quote do
          defp unquote(caller)(_, value, path) do
            unquote(:"#{parent}-additional_properties")(value, path)
          end
        end
      ] ++ [Exonerate.Buildable.build(additional_properties)]
    end

    defp schema_dependency_call(_path, %{schema_dependencies: nil}), do: :ok
    defp schema_dependency_call(path, _) do
      quote do
        unquote(:"#{path}-dependencies")(object, path)
      end
    end

    defp schema_dependency_helpers(_path, %{schema_dependencies: nil}), do: []
    defp schema_dependency_helpers(path, %{schema_dependencies: schema_dependencies}) do
      {calls, deps} = schema_dependencies
      |> Enum.map(fn {key, spec} ->
        {
          quote do
            defp unquote(path)(object, unquote(key), path) do
              unquote(:"#{path}-#{key}")(object, path)
            end
          end,
          Exonerate.Buildable.build(spec)
        }
      end)
      |> Enum.unzip

      [quote do
        defp unquote(path)(object, path) do
          Enum.each(object, fn {k, _} ->
            unless (error = unquote(path)(object, k, path)) == :ok do
              throw error
            end
          end)
        catch
          error = {:mismatch, _} -> error
        end
      end] ++ calls ++ [quote do
        defp unquote(path)(_, _, _), do: :ok
      end] ++ deps
    end
  end
end
