defmodule Exonerate.Types.Object do
  @enforce_keys [:method]
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

  def build(method, params) do
    properties = if props = params["properties"] do
      props
      |> Enum.map(fn {prop, spec} ->
        {prop, Builder.to_struct(spec, :"#{method}-properties-#{prop}")}
      end)
      |> Map.new
    end

    pattern_properties = if props = params["patternProperties"] do
      props
      |> Enum.map(fn {prop, spec} ->
        {prop, Builder.to_struct(spec, :"#{method}-pattern_properties-#{prop}")}
      end)
      |> Map.new
    end

    property_names = if props = params["propertyNames"] do
      String.build(:"#{method}-property_names", props)
    end

    additional_properties = case params["additionalProperties"] do
      default when default in [true, nil] -> nil
      props -> Builder.to_struct(props, :"#{method}-additional_properties")
    end

    {property_dependencies, schema_dependencies} = if props = params["dependencies"] do
      props
      |> Enum.map(fn
        {k, v} when is_map(v)->
          {k, v |> Map.put("type", "object") |> Builder.to_struct(:"#{method}-dependencies-#{k}")}
        kv -> kv
        end)
      |> Enum.split_with(fn {_k, v} -> is_list(v) end)
    else
      {nil, nil}
    end


    %__MODULE__{
      method: method,
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

    def build(params = %{method: method}) do
      guard_properties =
        size_branch(method, :<, params.min_properties) ++
        size_branch(method, :>, params.max_properties) ++
        required_branch(method, params.required) ++
        property_dependencies(method, params.property_dependencies)

      quote do
        defp unquote(method)(value, path) when not is_map(value) do
          {:mismatch, {path, value}}
        end
        unquote_splicing(guard_properties)
        unquote_splicing(properties_filter(method, params))
      end
    end

    defp size_branch(_, _, nil), do: []
    defp size_branch(method, op, value) do
      size_comp = {op, [], [quote do map_size(object) end, value]}
      [quote do
        defp unquote(method)(object, path) when unquote(size_comp) do
          {:mismatch, {path, object}}
        end
      end]
    end

    defp required_branch(_, nil), do: []
    defp required_branch(method, requireds) do
      required_guards = requireds
      |> Enum.map(&quote do not is_map_key(object, unquote(&1)) end)
      |> Enum.reduce(&quote do unquote(&1) or unquote(&2) end)

      [quote do
        defp unquote(method)(object, path) when unquote(required_guards) do
          {:mismatch, {path, object}}
        end
      end]
    end

    defp property_dependencies(_, nil), do: []
    defp property_dependencies(method, spec) do
      spec
      |> Enum.map(fn {key, deps} ->
        dep_guard = deps
        |> Enum.map(&quote do not is_map_key(object, unquote(&1)) end)
        |> Enum.reduce(&quote do unquote(&1) or unquote(&2) end)

        quote do
          defp unquote(method)(object, path) when is_map_key(object, unquote(key)) and unquote(dep_guard) do
            {:mismatch, {path, object}}
          end
        end
      end)
    end

    defp properties_filter(method, props = %{properties: nil, pattern_properties: nil, property_names: nil}) do
      [quote do
        defp unquote(method)(_, _) do
          unquote(schema_dependency_call(method, props))
        end
      end] ++
      schema_dependency_helpers(method, props)
    end
    defp properties_filter(method, params = %{properties: _, pattern_properties: nil, property_names: nil}) do
      [quote do
        defp unquote(method)(object, path) do
          Enum.each(object, fn {k, v} ->
            unless (error = unquote(:"#{method}-properties")(k, v, path)) == :ok do
              throw error
            end
          end)
          unquote(schema_dependency_call(method, params))
        catch
          error = {:mismatch, _} -> error
        end
      end]
      ++ properties_helpers(method, params)
      ++ schema_dependency_helpers(:"#{method}-dependencies", params)
    end
    defp properties_filter(method, params = %{properties: nil, pattern_properties: _, property_names: nil}) do
      patterns = Map.keys(params.pattern_properties)
      [quote do
        defp unquote(method)(object, path) do
          Enum.each(object, fn {key, param} ->
            unless (error = unquote(:"#{method}-pattern_properties")(key, param, path, unquote(patterns))) == :ok do
              throw error
            end
          end)
          unquote(schema_dependency_call(method, params))
        catch
          error = {:mismatch, _} -> error
        end
      end]
      ++ pattern_properties_helpers(method, params)
      ++ schema_dependency_helpers(:"#{method}-dependencies", params)
    end
    defp properties_filter(method, params = %{properties: nil, pattern_properties: nil, property_names: _}) do
      [quote do
        defp unquote(method)(object, path) do
          Enum.each(object, fn {key, param} ->
            unless (error = unquote(:"#{method}-property_names")(key, param, path)) == :ok do
              throw error
            end
          end)
          unquote(schema_dependency_call(method, params))
        catch
          error = {:mismatch, _} -> error
        end
      end]
      ++ property_names_helpers(method, params)
      ++ schema_dependency_helpers(:"#{method}-dependencies", params)
    end

    defp properties_helpers(method, params = %{properties: properties}) do
      specs = properties
      |> Map.values
      |> Enum.map(&Exonerate.Buildable.build/1)

      Enum.map(properties, fn {key, spec} ->
        quote do
          defp unquote(:"#{method}-properties")(unquote(key), param, path) do
            unquote(spec.method)(param, path)
          end
        end
      end) ++ filters_fallback(:"#{method}-properties", method, params) ++ specs
    end

    defp pattern_properties_helpers(method, params = %{pattern_properties: pattern_properties}) do
      {filters, specs} = pattern_properties
      |> Enum.map(fn {key, value} ->
        {
          quote do
            defp unquote(:"#{method}-pattern_properties")(key, param, path, [unquote(key) | rest]) do
              if key =~ sigil_r(<<unquote(key)>>, []) do
                unquote(:"#{method}-pattern_properties-#{key}")(param, path)
              else
                unquote(:"#{method}-pattern_properties")(key, param, path, rest)
              end
            end
          end,
          Exonerate.Buildable.build(value)
        }
      end)
      |> Enum.unzip

      fallback = if params.additional_properties do
        [quote do
          defp unquote(:"#{method}-pattern_properties")(key, param, path, []) do
            unquote(:"#{method}-additional_properties")(param, path)
          end
        end]
      else
        [quote do
          defp unquote(:"#{method}-pattern_properties")(_, _), do: :ok
        end]
      end

      filters ++ fallback ++ filters_fallback(method, params) ++ specs
    end

    defp property_names_helpers(method, params) do
      [quote do
        defp unquote(:"#{method}-property_names")(key, _, path) do
          unquote(:"#{method}-property_names")(key, path)
        end
      end] ++ [Exonerate.Buildable.build(params.property_names)]
    end

    defp filters_fallback(method, props), do: filters_fallback(method, method, props)
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

    defp schema_dependency_call(_method, %{schema_dependencies: nil}), do: :ok
    defp schema_dependency_call(method, _) do
      quote do
        unquote(:"#{method}-dependencies")(object, path)
      end
    end

    defp schema_dependency_helpers(_method, %{schema_dependencies: nil}), do: []
    defp schema_dependency_helpers(method, %{schema_dependencies: schema_dependencies}) do
      {calls, deps} = schema_dependencies
      |> Enum.map(fn {key, spec} ->
        {
          quote do
            defp unquote(method)(object, unquote(key), path) do
              unquote(:"#{method}-#{key}")(object, path)
            end
          end,
          Exonerate.Buildable.build(spec)
        }
      end)
      |> Enum.unzip

      [quote do
        defp unquote(method)(object, path) do
          Enum.each(object, fn {k, _} ->
            unless (error = unquote(method)(object, k, path)) == :ok do
              throw error
            end
          end)
        catch
          error = {:mismatch, _} -> error
        end
      end] ++ calls ++ [quote do
        defp unquote(method)(_, _, _), do: :ok
      end] ++ deps
    end
  end
end
