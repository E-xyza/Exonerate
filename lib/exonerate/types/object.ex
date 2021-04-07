defmodule Exonerate.Types.Object do
  @enforce_keys [:method]
  @props ~w(
    min_properties
    max_properties
    property_names
    properties
    additional_properties
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

    property_names = if props = params["propertyNames"] do
      String.build(:"#{method}-property_names_impl", props)
    end

    additional_properties = case params["additionalProperties"] do
      default when default in [true, nil] -> nil
      props -> Builder.to_struct(props, :"#{method}-additional_properties_impl")
    end

    %__MODULE__{
      method: method,
      min_properties: params["minProperties"],
      max_properties: params["maxProperties"],
      properties:     properties,
      property_names: property_names,
      additional_properties: additional_properties
    }
  end

  def props, do: @props

  defimpl Exonerate.Buildable do

    alias Exonerate.Types.Object

    @guard_filters [:max_properties, :min_properties]

    def build(params = %{method: method}) do
      guard_properties =
        size_branch(method, :<, params.min_properties) ++
        size_branch(method, :>, params.max_properties)

      quote do
        defp unquote(method)(value, path) when not is_map(value) do
          {:mismatch, {path, value}}
        end
        unquote_splicing(guard_properties)
        unquote(properties_filter(method, params.properties))
        unquote_splicing(properties_helpers(method, params))
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

    defp next_call([], _), do: :ok
    defp next_call([{filter, _}| _], method) do
      quote do
        unquote(:"#{method}-#{filter}")(object, path)
      end
    end

    defp properties_filter(method, nil) do
      quote do
        defp unquote(method)(_object, _path), do: :ok
      end
    end
    defp properties_filter(method, _) do
      quote do
        defp unquote(method)(object, path) do
          Enum.each(object, fn {k, v} ->
            unless (error = unquote(:"#{method}-properties")(k, v, path)) == :ok do
              throw error
            end
          end)
        catch
          error = {:mismatch, _} -> error
        end
      end
    end

    defp properties_helpers(_method, %{properties: nil}), do: []
    defp properties_helpers(method, params) do
      {props, helpers} = params.properties
      |> Enum.map(fn {k, v} ->
        {
          quote do
            defp unquote(:"#{method}-properties")(unquote(k), property, path) do
              unquote(v.method)(property, path <> "/properties/#{unquote(k)}")
            end
          end,
          Exonerate.Buildable.build(v)
        }
      end)
      |> Enum.unzip

      default_prop = [quote do
        defp unquote(:"#{method}-properties")(_, property, path) do
          :ok
        end
      end]

      props ++ default_prop ++ helpers
    end
  end
end
