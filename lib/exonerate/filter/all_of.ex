defmodule Exonerate.Filter.AllOf do
  @moduledoc false
  # the filter for "anyOf" parameters

  alias Exonerate.Filter

  @behaviour Filter

  @impl true
  def filter(%{"allOf" => schemas}, state) do
    {calls, helpers} = schemas
    |> Enum.with_index
    |> Enum.map(fn {schema, index} ->
      all_of_branch = Exonerate.join(state.path, "allOf/#{index}")
      {all_of_branch, Filter.from_schema(schema, all_of_branch)}
    end)
    |> Enum.unzip

    {helpers, %{state | extra_validations: calls ++ state.extra_validations}}
  end
  def filter(_schema, state), do: {[], state}
end
