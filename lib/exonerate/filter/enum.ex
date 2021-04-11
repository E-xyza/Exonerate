defmodule Exonerate.Filter.Enum do
  @moduledoc false
  # the filter for the "enum" parameter.

  @behaviour Exonerate.Filter

  import Exonerate.Filter, only: [filter_types: 2]

  @impl true
  def filter(%{"enum" => enum}, state) do
    {[quote do
      defp unquote(state.path)(value, path) when value not in unquote(Macro.escape(enum)) do
        Exonerate.mismatch(value, path, schema_subpath: "enum")
      end
    end], filter_types(state, enum)}
  end
  def filter(_spec, state), do: {[], state}
end
