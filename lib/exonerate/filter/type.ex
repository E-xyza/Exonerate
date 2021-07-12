defmodule Exonerate.Filter.Type do
  @moduledoc false

  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  
  defstruct [:context, :types]

  alias Exonerate.Type
  alias Exonerate.Validator

  # the filter for the "type" parameter.

  @behaviour Exonerate.Filter

  @spec parse(Validator.t, Type.json) :: Validator.t
  def parse(validator = %Validator{}, %{"type" => schema}) do
    types = schema
    |> List.wrap
    |> Enum.map(&Type.from_string/1)
    |> Map.new(&{&1, nil})

    %{validator |
      types: Type.intersection(validator.types, types),
      guards: [%__MODULE__{context: validator, types: Map.keys(types)} | validator.guards]}
  end

  def compile(%__MODULE__{context: context, types: types}) do
    quote do
      defp unquote(Validator.to_fun(context))(value, path)
        when not (Exonerate.chain_guards(value, unquote(types))) do
          Exonerate.mismatch(value, path, guard: "type")
      end
    end
  end
end
