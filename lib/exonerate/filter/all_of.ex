defmodule Exonerate.Filter.AllOf do
  @moduledoc false

  @behaviour Exonerate.Filter

  @impl true
  def append_filter(schema, validation) do
    calls = validation.calls
    |> Map.get(:all, [])
    |> List.insert_at(0, name(validation))

    children = code(schema, validation) ++ validation.children

    validation
    |> put_in([:calls, :all], calls)
    |> put_in([:children], children)
  end

  def name(validation) do
    Exonerate.path(["allOf" | validation.path])
  end

  def code(schema, validation) do
    {calls, funs} = schema
    |> Enum.with_index
    |> Enum.map(fn {subschema, index} ->
      subpath = [to_string(index) , "allOf" | validation.path]
      {
        quote do unquote(Exonerate.path(subpath))(value, path) end,
        Exonerate.Validation.from_schema(subschema, subpath)
      }
    end)
    |> Enum.unzip

    [quote do
      def unquote(name(validation))(value, path) do
        unquote_splicing(calls)
      end
    end] ++ funs
  end
end
