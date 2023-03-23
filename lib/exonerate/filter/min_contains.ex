defmodule Exonerate.Filter.MinContains do
  @moduledoc false

  # minContains filter is handled at the array iterator level.

  defmacro filter(_name, _pointer, _opts), do: []
end
