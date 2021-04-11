defmodule Exonerate.Filter.AnyOf do
  @moduledoc false
  # the filter for "anyOf" parameters

  alias Exonerate.Filter

  @behaviour Filter

  @impl true
  def filter(%{"anyOf" => schemas}, state) do
    {calls, helpers} = schemas
    |> Enum.with_index
    |> Enum.map(fn {schema, index} ->
      any_of_branch = Exonerate.join(state.path, "anyOf/#{index}")

      {
        quote do
          found! = found! || try do
            unquote(any_of_branch)(value, path)
          catch
            {:mismatch, _} -> false
          end
        end,
        Filter.from_schema(schema, any_of_branch)
      }

      end)
    |> Enum.unzip

    footer = &quote do
      defp unquote(&1)(value, path) do
        found! = false
        unquote_splicing(calls)
        if found! do
          :ok
        else
          Exonerate.mismatch(value, path, schema_subpath: "anyOf")
        end
      end
    end

    {helpers, %{state | footer: footer}}
  end
  def filter(_schema, state), do: {[], state}
end
