defmodule Exonerate.Filter.MinItems do
  @moduledoc false

  # minItems filter is handled at the array iterator level.

  defmacro filter(_name, _pointer, _opts) do
    []
  end
end
