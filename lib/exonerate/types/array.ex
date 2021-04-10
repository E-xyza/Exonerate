defmodule Exonerate.Types.Array do
  #use Exonerate.Builder, ~w(
  #  contains
  #  items
  #  tuple
  #  min_items
  #  max_items
  #  unique_items
  #  additional_items
  #)a

#  def build(schema, path) do
#    items = case schema["items"] do
#      nil -> nil
#      item when not is_list(item) ->
#        Exonerate.Builder.to_struct(item, Exonerate.Builder.join(path, "items"))
#      _ -> nil
#    end
#
#    tuple = case schema["items"] do
#      items_list when is_list(items_list) ->
#        items_list
#        |> Enum.with_index
#        |> Enum.map(fn {item, index} ->
#          Exonerate.Builder.to_struct(item, Exonerate.Builder.join(path, "items/#{index}"))
#        end)
#      _ -> nil
#    end
#
#    contains = if contains = schema["contains"] do
#      Exonerate.Builder.to_struct(contains, Exonerate.Builder.join(path, "contains"))
#    end
#
#    additional_items = case schema["additionalItems"] do
#      default when default in [nil, true] -> nil
#      spec ->
#        Exonerate.Builder.to_struct(spec, Exonerate.Builder.join(path, "additionalItems"))
#    end
#
#    build_generic(%__MODULE__{
#      path: path,
#      items: items,
#      tuple: tuple,
#      contains: contains,
#      min_items: schema["minItems"],
#      max_items: schema["maxItems"],
#      unique_items: schema["uniqueItems"],
#      additional_items: additional_items
#    }, schema)
#  end
#
#  defimpl Exonerate.Buildable do
#
#    use Exonerate.GenericTools, [:filter_generic]
#
#    def build(spec = %{path: path}) do
#      quote do
#        defp unquote(path)(value, path) when not is_list(value) do
#          Exonerate.Builder.mismatch(value, path, subpath: "type")
#        end
#        unquote_splicing(filter_generic(spec))
#        defp unquote(path)(list, path) do
#          initial! = %{index: 0}
#          unquote(unique_initializer(spec))
#          unquote(contains_initializer(spec))
#          unquote(tuple_initializer(spec))
#          reduction = Enum.reduce(list, initial!, fn item, acc! ->
#            unquote(max_items_validation(spec))
#            unquote(unique_validation(spec))
#            unquote(items_validation(spec))
#            unquote(tuple_validator(spec))
#            unquote(contains_iterator(spec))
#            %{acc! | index: acc!.index + 1}
#          end)
#          unquote(min_items_validation(spec))
#          unquote(contains_validation(spec))
#          :ok
#        end
#        unquote(items_helper(spec))
#        unquote(contains_helper(spec))
#        unquote_splicing(tuple_helpers(spec))
#        unquote(additional_items_helpers(spec))
#      end
#    end
#
#    defp max_items_validation(%{max_items: nil}), do: :ok
#    defp max_items_validation(%{max_items: max_items}) do
#      quote do
#        if acc!.index == unquote(max_items), do:
#          Exonerate.Builder.mismatch(list, path, subpath: "maxItems")
#      end
#    end
#
#    defp min_items_validation(%{min_items: nil}), do: :ok
#    defp min_items_validation(%{min_items: min_items}) do
#      quote do
#        if reduction.index < unquote(min_items), do:
#          Exonerate.Builder.mismatch(list, path, subpath: "minItems")
#      end
#    end
#
#    defp unique_initializer(%{unique_items: true}) do
#      quote do
#        initial! = Map.put(initial!, :uniques, MapSet.new())
#      end
#    end
#    defp unique_initializer(_), do: :ok
#
#    defp unique_validation(%{unique_items: true}) do
#      quote do
#        if item in acc!.uniques, do:
#          Exonerate.Builder.mismatch(
#            item,
#            Path.join(path, "#{acc!.index}"),
#            subpath: "uniqueItems")
#
#        acc! = %{acc! | uniques: MapSet.put(acc!.uniques, item)}
#      end
#    end
#    defp unique_validation(_), do: :ok
#
#    defp items_validation(%{items: nil}), do: :ok
#    defp items_validation(%{path: spec_path}) do
#      items_path = Exonerate.Builder.join(spec_path, "items")
#      quote do
#        unquote(items_path)(item, Path.join(path, "#{acc!.index}"))
#      end
#    end
#
#    defp items_helper(%{items: nil}), do: :ok
#    defp items_helper(%{items: items}) do
#      Exonerate.Buildable.build(items)
#    end
#
#    defp contains_initializer(%{contains: nil}), do: :ok
#    defp contains_initializer(%{path: spec_path}) do
#      contains_path = Exonerate.Builder.join(spec_path, "contains")
#      lambda = {:&, [], [{:/, [], [{contains_path, [], Elixir}, 2]}]}
#      quote do
#        initial! = Map.put(initial!, :contains, unquote(lambda))
#      end
#    end
#
#    defp contains_iterator(%{contains: nil}), do: :ok
#    defp contains_iterator(%{contains: _}) do
#      quote do
#        acc! = try do
#          if contains = acc!.contains do
#            contains.(item, path)
#            Map.delete(acc!, :contains)
#          else
#            acc!
#          end
#        catch
#          {:mismatch, _} -> acc!
#        end
#      end
#    end
#
#    defp contains_validation(%{contains: nil}), do: :ok
#    defp contains_validation(%{contains: _}) do
#      quote do
#        if is_map_key(reduction, :contains) do
#          Exonerate.Builder.mismatch(list, path, subpath: "contains")
#        end
#      end
#    end
#
#    defp contains_helper(%{contains: nil}), do: :ok
#    defp contains_helper(spec) do
#      Exonerate.Buildable.build(spec.contains)
#    end
#
#    defp tuple_initializer(%{tuple: nil}), do: :ok
#    defp tuple_initializer(spec = %{tuple: tuple}) do
#      funs = tuple
#      |> Enum.with_index
#      |> Enum.map(fn {_, index} ->
#        tuple_path = Exonerate.Builder.join(spec.path, "items/#{index}")
#        {index, {:&, [], [{:/, [], [{tuple_path, [], Elixir}, 2]}]}}
#      end)
#
#      tuple_map = {:%{}, [], funs}
#      quote do
#        initial! = Map.merge(initial!, unquote(tuple_map))
#      end
#    end
#
#    defp tuple_validator(%{tuple: nil}), do: :ok
#    defp tuple_validator(spec = %{tuple: _}) do
#      quote do
#        if fun = acc![acc!.index] do
#          fun.(item, Path.join(path, "#{acc!.index}"))
#        else
#          unquote(additional_items_call(spec))
#        end
#      end
#    end
#
#    defp tuple_helpers(%{tuple: nil}), do: []
#    defp tuple_helpers(%{tuple: tuple}) do
#      Enum.map(tuple, &Exonerate.Buildable.build/1)
#    end
#
#    defp additional_items_call(%{additional_items: nil}), do: :ok
#    defp additional_items_call(%{additional_items: spec}) do
#      quote do
#        unquote(spec.path)(item, Path.join(path, "#{acc!.index}"))
#      end
#    end
#
#    defp additional_items_helpers(%{additional_items: nil}), do: :ok
#    defp additional_items_helpers(%{additional_items: spec}) do
#      Exonerate.Buildable.build(spec)
#    end
#
#  end
end

