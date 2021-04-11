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

      {
        quote do
          unquote(all_of_branch)(value, path)
        end,
        Filter.from_schema(schema, all_of_branch)
      }

    end)
    |> Enum.unzip

    footer = &quote do
      defp unquote(&1)(value, path) do
        unquote_splicing(calls)
      end
    end

    {helpers, %{state | footer: footer}}
  end
  def filter(_schema, state), do: {[], state}
end
