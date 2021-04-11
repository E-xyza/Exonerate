defmodule Exonerate.Filter.Not do
  @moduledoc false
  # the filter for "anyOf" parameters

  alias Exonerate.Filter

  @behaviour Filter

  @impl true
  def filter(%{"not" => schema}, state) do
    not_branch = Exonerate.join(state.path, "not")

    footer = &quote do
      defp unquote(&1)(value, path) do
        try do
          unquote(not_branch)(value, path)
        catch
          mismatch = {:mismatch, _} -> mismatch
        end
        |> case do
          :ok -> Exonerate.mismatch(value, path, schema_subpath: "not")
          {:mismatch, _} -> :ok
        end
      end
    end

    {[Filter.from_schema(schema, not_branch)], %{state | footer: footer}}
  end
  def filter(_schema, state), do: {[], state}
end
