defmodule Exonerate.Filter.MinLength do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator
  defstruct [:context, :length]

  def parse(artifact = %Exonerate.Type.String{}, %{"minLength" => length}) do
    %{artifact |
      pipeline: [{fun(artifact), []} | artifact.pipeline],
      filters: [%__MODULE__{context: artifact.context, length: length} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{}) do
    {[], [quote do
      defp unquote(fun(filter))(string, path) do
        if String.length(string) < unquote(filter.length) do
          Exonerate.mismatch(string, path)
        end
        string
      end
    end]}
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("minLength")
    |> Validator.to_fun
  end
end
