defmodule Exonerate.Filter do
  @moduledoc false

  alias Exonerate.Validation

  @callback analyze(Validation.t) :: Validation.t

  def from_string(filter), do: String.to_atom("Elixir.Exonerate.Filter.#{String.capitalize(filter)}")
end
