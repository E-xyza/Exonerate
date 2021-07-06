defmodule Exonerate.Filter.UnevaluatedProperties do
  @behaviour Exonerate.Filter

  alias Exonerate.Type
  require Type

  def append_filter(object, validation) when Type.is_schema(object) do
    #collection_calls = validation.collection_calls
    #|> Map.get(:object, [])
    #|> List.insert_at(0, name(validation))
#
    #children = code(object, validation) ++ validation.children
#
    #validation
    #|> put_in([:collection_calls, :object], collection_calls)
    #|> put_in([:children], children)

    validation
  end

  defp name(validation) do
    Exonerate.path_to_call(["unevaluatedProperties" | validation.path])
  end

  defp code(_object, _validation) do
    []
  end
end
