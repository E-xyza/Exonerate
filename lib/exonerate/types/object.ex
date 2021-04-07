defmodule Exonerate.Types.Object do
  @enforce_keys [:method]
  defstruct @enforce_keys ++ [
    :min_properties, :max_properties, :property_names
  ]

  def build(method, params) do
    prop_names = if string_props = params["propertyNames"] do
      method
      |> prop_name_accessory_fn
      |> Exonerate.Types.String.build(string_props)
    end

    %__MODULE__{
      method: method,
      min_properties: params["minProperties"],
      max_properties: params["maxProperties"],
      property_names: prop_names
    }
  end

  def prop_name_accessory_fn(method), do: :"#{method}_property_name"

  defimpl Exonerate.Buildable do

    alias Exonerate.Types.Object

    def build(params = %{method: method}) do
      cond_branches =
        prop_size_branch(:<, params.min_properties) ++
        prop_size_branch(:>, params.max_properties) ++
        prop_name_branch(method, params.property_names) ++
        [arrow(true, :ok)]

      cond_body = {:cond, [], [[do: cond_branches]]}

      obj_check = {:defp, [],
      [
        {:when, [],
         [
           {method, [], [v(:object), v(:path)]},
           {:is_map, [], [v(:object)]}
         ]},
        [do: cond_body]
      ]}

      accessory_functions =
        prop_name_accessory(params)

      quote do
        unquote(obj_check)
        defp unquote(method)(content, path) do
          {:mismatch, {path, content}}
        end

        unquote_splicing(accessory_functions)
      end
    end

    defp prop_size_branch(_op, nil), do: []
    defp prop_size_branch(op, limit) do
      [arrow({op, [], [call(:map_size, [v(:object)]), limit]}, mismatch())]
    end

    def prop_name_branch(_method, nil), do: []
    def prop_name_branch(method, _) do
      pp_method = Object.prop_name_accessory_fn(method)
      [arrow({:=, [], [v(:mismatch), {pp_method, [], [v(:object), v(:path)]}]}, v(:mismatch))]
    end

    def prop_name_accessory(%{property_names: nil}), do: []
    def prop_name_accessory(%{property_names: props}) do
      props
      |> Exonerate.Buildable.build
      |> List.wrap
    end

    defp call(fun, params), do: {fun, [], params}

    defp mismatch, do: {:mismatch, {v(:path), v(:object)}}

    defp arrow(left, right), do: {:->, [], [[left], right]}
    defp v(name), do: {name, [], Elixir}
  end
end
