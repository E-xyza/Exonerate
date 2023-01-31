# defmodule Exonerate.Filter.UnevaluatedItems do
#  @behaviour Exonerate.Filter
#
#  alias Exonerate.Type
#  require Type
#
#  def append_filter(object, validation) when Type.is_schema(object) do
#    collection_calls = validation.collection_calls
#    |> Map.get(:array, [])
#    |> List.insert_at(0, name(validation))
#    |> Kernel.++([reset(validation)])
#
#    children = code(object, validation) ++ validation.children
#
#    validation
#    |> put_in([:collection_calls, :array], collection_calls)
#    |> put_in([:children], children)
#  end
#
#  defp name(validation) do
#    Exonerate.path_to_call(["unevaluatedItems" | validation.path])
#  end
#
#  defp reset(validation) do
#    Exonerate.path_to_call(["unevaluatedItems_reset_" | validation.path])
#  end
#
#  defp code(object, validation) do
#    [quote do
#      defp unquote(name(validation))({value, _}, acc, path) do
#        if acc.unevaluated do
#          unquote(name(validation))(value, Path.join(path, "unevaluatedItems"))
#        end
#        acc
#      end
#      defp unquote(reset(validation))(unit, acc, path) do
#        Map.put(acc, :unevaluated, true)
#      end
#      unquote(Exonerate.Validation.from_schema(object, ["unevaluatedItems" | validation.path]))
#    end]
#  end
# end
