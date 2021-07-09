defmodule Exonerate.Filter.Type do
  @moduledoc false

  alias Exonerate.Type
  alias Exonerate.Validator

  # the filter for the "type" parameter.

  @behaviour Exonerate.Filter

  @spec parse(Validator.t, Type.json) :: Validator.t
  def parse(validation, %{"type" => schema}) do
    types = schema
    |> List.wrap
    |> Enum.map(&Type.from_string/1)
    |> Map.new(&{&1, nil})

    %{validation | types: Type.intersection(validation.types, types)}
  end
end
