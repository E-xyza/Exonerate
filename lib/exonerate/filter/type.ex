defmodule Exonerate.Filter.Type do
  @moduledoc false

  alias Exonerate.Type
  alias Exonerate.Validator

  # the filter for the "type" parameter.

  @behaviour Exonerate.Filter

  @spec analyze(Validator.t) :: Validator.t
  def analyze(validation) do
    types = validation
    |> Validator.traverse()
    |> List.wrap
    |> Enum.map(&Type.from_string/1)
    |> MapSet.new

    %{validation | types: MapSet.intersection(validation.types, types)}
  end
end
