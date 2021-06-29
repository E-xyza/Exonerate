defmodule Exonerate.Filter.Else do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(schema, validation) do
    validation
    |> put_in([:calls, :else], [name(validation)])
    |> put_in([:children], [code(schema, validation) | validation.children])
  end

  defp name(validation) do
    Exonerate.path(["else" | validation.path])
  end

  defp code(schema, validation) do
    [Exonerate.Validation.from_schema(schema, ["else" | validation.path])]
  end
end
