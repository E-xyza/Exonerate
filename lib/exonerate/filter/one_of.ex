defmodule Exonerate.Filter.OneOf do
  @moduledoc false
  # the filter for "oneOf" parameters

  alias Exonerate.Filter

  @behaviour Filter

  @impl true
  def filter(%{"oneOf" => schemas}, state) do
    {calls, helpers} = schemas
    |> Enum.with_index
    |> Enum.map(fn {schema, index} ->
      any_of_branch = Exonerate.join(state.path, "oneOf/#{index}")

      {
        quote do
          if found! == 2 do
            Exonerate.mismatch(value, path, schema_subpath: "oneOf")
          end

          found! =
            try do
              unquote(any_of_branch)(value, path)
              found! + 1
            catch
              {:mismatch, _} -> found!
            end
        end,
        Filter.from_schema(schema, any_of_branch)
      }

      end)
    |> Enum.unzip

    footer = &quote do
      defp unquote(&1)(value, path) do
        found! = 0
        unquote_splicing(calls)
        if found! == 1 do
          :ok
        else
          Exonerate.mismatch(value, path, schema_subpath: "oneOf")
        end
      end
    end

    {helpers, %{state | footer: footer}}
  end
  def filter(_schema, state), do: {[], state}
end
