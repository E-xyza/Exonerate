# defmodule Exonerate.Filter.ContentMediaType do
#  @behaviour Exonerate.Filter
#
#  @impl true
#  def append_filter(media_type, validation) do
#    #calls = validation.collection_calls
#    #|> Map.get(:array, [])
#    #|> List.insert_at(0, name(validation))
##
#    #children = code(maximum, validation) ++ validation.children
##
#    #validation
#    #|> put_in([:collection_calls, :array], calls)
#    #|> put_in([:children], children)
#    validation
#  end
#
#  #defp name(validation) do
#  #  Exonerate.path_to_call(["maxItems" | validation.path])
#  #end
##
#  #defp code(maximum, validation) do
#  #  [quote do
#  #     defp unquote(name(validation))({_, index}, acc, path) do
#  #       if index >= unquote(maximum), do: throw {:max, "maxItems"}
#  #       acc
#  #     end
#  #   end]
#  #end
# end
#
