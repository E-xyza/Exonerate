defmodule Exonerate.Filter.MaxLength do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}


  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :length, :format_binary]

  def parse(artifact = %Exonerate.Type.String{}, %{"maxLength" => length}) do
    pipeline = List.wrap(unless artifact.format_binary, do: fun(artifact, "maxLength"))

    %{artifact |
      pipeline: pipeline ++ artifact.pipeline,
      filters: [%__MODULE__{context: artifact.context, length: length, format_binary: artifact.format_binary} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{format_binary: true}) do
    {[quote do
      defp unquote(fun(filter, []))(string, path) when is_binary(string) and byte_size(string) > unquote(filter.length) do
        Exonerate.mismatch(string, path, guard: "maxLength")
      end
    end],[]}
  end
  def compile(filter = %__MODULE__{}) do
    {[], [quote do
      defp unquote(fun(filter, "maxLength"))(string, path) do
        if String.length(string) > unquote(filter.length) do
          Exonerate.mismatch(string, path)
        end
        string
      end
    end]}
  end
end
