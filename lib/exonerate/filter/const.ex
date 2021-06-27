#defmodule Exonerate.Filter.Const do
#  @moduledoc false
#
#  @behaviour Exonerate.Filter
#  # the filter for the "const" parameter.
#
#  import Exonerate.Filter, only: [filter_type: 2]
#
#  @impl true
#  def filter(%{"const" => const}, state) do
#    {[quote do
#      defp unquote(state.path)(value, path) when value !== unquote(Macro.escape(const)) do
#        Exonerate.mismatch(value, path, schema_subpath: "const")
#      end
#    end], filter_type(state, const)}
#  end
#  def filter(_spec, state), do: {[], state}
#
#end
#
