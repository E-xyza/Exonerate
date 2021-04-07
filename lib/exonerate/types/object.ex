defmodule Exonerate.Types.Object do
  @enforce_keys [:method]
  @props ~w(min_properties max_properties property_names)a

  defstruct @enforce_keys ++ @props

  def build(method, params) do
    %__MODULE__{
      method: method,
      min_properties: params["minProperties"],
      max_properties: params["maxProperties"],
      property_names: params["propertyNames"],
      additional_properties: params["additionalProperties"]
    }
  end

  def props, do: @props

  defimpl Exonerate.Buildable do

    alias Exonerate.Types.Object

    @guard_filters [:max_properties, :min_properties]

    def build(params = %{method: method}) do
      filter_params = params
      |> Map.take(Object.props() -- @guard_filters)
      |> Enum.filter(&(elem(&1, 1)))
      |> Enum.to_list

      guard_properties =
        size_branch(method, :<, params.min_properties) ++
        size_branch(method, :>, params.max_properties)

      quote do
        defp unquote(method)(value, path) when not is_map(value) do
          {:mismatch, path, value}
        end
        unquote_splicing(guard_properties)
        defp unquote(method)(object, path) do
          unquote(next_call(filter_params, method))
        end
        defp unquote(method)(_, _), do: :ok

        unquote_splicing(helpers(filter_params, method))
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

    defp helpers([{filter, value} | rest], method) do
      [quote do
        defp unquote(:"#{method}-#{filter}")(object, path) do
          if unquote(filter_condition(filter, value)) do
            unquote(next_call(rest, method))
          else
            {:mismatch, {path, object}}
          end
        end
      end | helpers(rest, method)]
    end
    defp helpers([], _), do: []

    defp filter_condition(:property_names, _value) do
      true
    end
  end
end
