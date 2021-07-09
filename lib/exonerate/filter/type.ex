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
    |> Map.new(&{&1, nil})

    %{validation | types: Type.intersection(validation.types, types)}
  end
end
