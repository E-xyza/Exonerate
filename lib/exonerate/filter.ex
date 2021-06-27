defmodule Exonerate.Filter do
  @moduledoc false

  # define the append_filter callback that all filters must implement

  @callback append_filter(Exonerate.Type.json, Exonerate.Validation.t) :: Exonerate.Validation.t
end
