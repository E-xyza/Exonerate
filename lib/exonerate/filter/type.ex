defmodule Exonerate.Filter.Type do
  @moduledoc false

  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  defstruct [:context, :types]

  alias Exonerate.Type
  alias Exonerate.Context

  # the filter for the "type" parameter.

  @behaviour Exonerate.Filter

  @spec parse(Context.t(), Type.json()) :: Context.t()
  def parse(context = %Context{}, %{"type" => schema}) do
    types =
      schema
      |> List.wrap()
      |> Enum.map(&Type.from_string/1)
      |> Map.new(&{&1, nil})

    %{
      context
      | types: Type.intersection(context.types, types),
        guards: [%__MODULE__{context: context, types: Map.keys(types)} | context.guards]
    }
  end

  def compile(%__MODULE__{context: context, types: types}) do
    quote do
      defp unquote(Context.fun(context))(value, path)
           when not Exonerate.chain_guards(value, unquote(types)) do
        Exonerate.mismatch(value, path, guard: "type")
      end
    end
  end
end
