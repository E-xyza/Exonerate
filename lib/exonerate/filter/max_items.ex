defmodule Exonerate.Filter.MaxItems do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(_name, _pointer, _opts), do: []
end
