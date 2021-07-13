defmodule Exonerate.Filter.MaxLength do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Validator

  defstruct [:context, :length, :format_binary]

  def parse(artifact = %Exonerate.Type.String{}, %{"maxLength" => length}) do
    pipeline = List.wrap(unless artifact.format_binary, do: {fun(artifact), []})

    %{artifact |
      pipeline: pipeline ++ artifact.pipeline,
      filters: [%__MODULE__{context: artifact.context, length: length, format_binary: artifact.format_binary} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{format_binary: true}) do
    {[quote do
      defp unquote(fun0(filter))(string, path) when is_binary(string) and byte_size(string) > unquote(filter.length) do
        Exonerate.mismatch(string, path, guard: "maxLength")
      end
    end],[]}
  end
  def compile(filter = %__MODULE__{}) do
    {[], [quote do
      defp unquote(fun(filter))(string, path) do
        if String.length(string) > unquote(filter.length) do
          Exonerate.mismatch(string, path)
        end
        string
      end
    end]}
  end

  defp fun0(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.to_fun
  end

  defp fun(filter_or_artifact = %_{}) do
    filter_or_artifact.context
    |> Validator.jump_into("maxLength")
    |> Validator.to_fun
  end
end
