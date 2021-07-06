defmodule Exonerate.Filter.Then do
  @behaviour Exonerate.Filter

  @impl true
  def append_filter(schema, validation) do
    validation
    |> put_in([:calls, :then], [name(validation)])
    |> put_in([:children], [code(schema, validation) | validation.children])
  end

  defp name(validation) do
    Exonerate.path_to_call(["then" | validation.path])
  end

  defp code(schema, validation) do
    [Exonerate.Validation.from_schema(schema, ["then" | validation.path])]
  end
end
